"""
AI Service
Handles integration with Azure AI services (OpenAI, Search, Document Intelligence)
"""

from typing import Optional, List, Dict, Any
import logging
import asyncio
import json
import os
from datetime import datetime
import aiofiles

# Azure SDK imports
from azure.identity import DefaultAzureCredential
from azure.search.documents.aio import SearchClient
from azure.search.documents.models import VectorizedQuery
from azure.ai.formrecognizer.aio import DocumentAnalysisClient
from azure.storage.blob.aio import BlobServiceClient
from openai import AsyncAzureOpenAI

from app.core.config import settings
from app.models.chat import ChatMessage

logger = logging.getLogger(__name__)


class AIService:
    """Service for AI operations and Azure integration"""
    
    def __init__(self):
        self.credential = DefaultAzureCredential()
        self._openai_client = None
        self._search_client = None
        self._document_client = None
        self._blob_client = None
    
    @property
    async def openai_client(self) -> Optional[AsyncAzureOpenAI]:
        """Get Azure OpenAI client"""
        if not self._openai_client and settings.AZURE_OPENAI_ENDPOINT and settings.AZURE_OPENAI_API_KEY:
            self._openai_client = AsyncAzureOpenAI(
                azure_endpoint=settings.AZURE_OPENAI_ENDPOINT,
                api_key=settings.AZURE_OPENAI_API_KEY,
                api_version=settings.AZURE_OPENAI_API_VERSION
            )
        return self._openai_client
    
    @property
    async def search_client(self) -> Optional[SearchClient]:
        """Get Azure AI Search client"""
        if not self._search_client and settings.AZURE_SEARCH_ENDPOINT and settings.AZURE_SEARCH_API_KEY:
            from azure.core.credentials import AzureKeyCredential
            self._search_client = SearchClient(
                endpoint=settings.AZURE_SEARCH_ENDPOINT,
                index_name=settings.AZURE_SEARCH_INDEX_NAME,
                credential=AzureKeyCredential(settings.AZURE_SEARCH_API_KEY)
            )
        return self._search_client
    
    @property
    async def document_client(self) -> Optional[DocumentAnalysisClient]:
        """Get Azure Document Intelligence client"""
        if not self._document_client:
            endpoint = settings.AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT
            api_key = settings.AZURE_DOCUMENT_INTELLIGENCE_API_KEY
            
            logger.info(f"Document Intelligence Endpoint: {endpoint}")
            logger.info(f"Document Intelligence API Key exists: {bool(api_key)}")
            logger.info(f"Document Intelligence API Key length: {len(api_key) if api_key else 0}")
            
            if endpoint and api_key:
                from azure.core.credentials import AzureKeyCredential
                # Strip trailing slash from endpoint if present
                endpoint = endpoint.rstrip('/')
                logger.info(f"Initializing Document Intelligence client with endpoint: {endpoint}")
                try:
                    self._document_client = DocumentAnalysisClient(
                        endpoint=endpoint,
                        credential=AzureKeyCredential(api_key)
                    )
                    logger.info("Document Intelligence client initialized successfully")
                except Exception as e:
                    logger.error(f"Failed to initialize Document Intelligence client: {e}")
                    self._document_client = None
            else:
                logger.warning("Document Intelligence credentials not configured - endpoint or API key is missing")
        return self._document_client
    
    @property
    async def blob_client(self) -> Optional[BlobServiceClient]:
        """Get Azure Blob Storage client"""
        if not self._blob_client and settings.AZURE_STORAGE_CONNECTION_STRING:
            self._blob_client = BlobServiceClient.from_connection_string(
                settings.AZURE_STORAGE_CONNECTION_STRING
            )
        return self._blob_client
    
    async def generate_chat_response(
        self, 
        user_message: str, 
        chat_history: List[ChatMessage],
        user_id: str,
        document_ids: Optional[List[str]] = None
    ) -> Optional[Dict[str, Any]]:
        """Generate AI response using Azure OpenAI with RAG"""
        try:
            # Detect if this is a general question (like "What is this about?", "Summarize", etc.)
            general_question_keywords = ["what is", "what's", "about", "summarize", "summary", "describe", "tell me about", "what does"]
            is_general_question = any(keyword in user_message.lower() for keyword in general_question_keywords)
            
            # For general questions with selected documents, get more content
            # Use the original query but increase limit to get more content
            search_query = user_message
            search_limit = 10 if (is_general_question and document_ids and len(document_ids) > 0) else 5
            
            if is_general_question and document_ids and len(document_ids) > 0:
                logger.info(f"General question detected with selected documents - retrieving more content (limit={search_limit})")
            
            # Search for relevant documents (filtered by document_ids if provided)
            search_results = await self.search_documents(search_query, user_id, document_ids=document_ids, limit=search_limit)
            
            # Build context from search results
            context = self._build_context_from_search(search_results, document_ids)
            
            # Build conversation history
            conversation = self._build_conversation_history(chat_history)
            
            # Generate AI response using Azure OpenAI
            ai_response = await self._generate_openai_response(
                user_message, 
                context, 
                conversation,
                document_ids
            )
            
            # Extract document sources
            sources = self._extract_sources_from_search(search_results)
            
            return {
                "content": ai_response,
                "sources": sources
            }
            
        except Exception as e:
            logger.error(f"AI response generation error: {e}")
            # Fallback to simple response if Azure services fail
            return await self._generate_fallback_response(user_message)
    
    async def search_documents(self, query: str, user_id: str, limit: int = 5, document_ids: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """Search documents using Azure AI Search"""
        try:
            search_client = await self.search_client
            
            if not search_client:
                logger.warning("Azure AI Search not configured, using fallback")
                return await self._fallback_search(query, user_id, limit, document_ids)
            
            # Build filter: always filter by user_id, and optionally by document_ids
            filter_parts = [f"user_id eq '{user_id}'"]
            if document_ids and len(document_ids) > 0:
                # Filter by specific document IDs
                # Ensure document IDs are properly formatted (handle UUID strings)
                document_id_filters = " or ".join([f"document_id eq '{str(doc_id)}'" for doc_id in document_ids])
                filter_parts.append(f"({document_id_filters})")
                logger.info(f"Filtering search to {len(document_ids)} selected document(s): {document_ids}")
            else:
                logger.info("Searching across all user documents (no document filter applied)")
            
            search_filter = " and ".join(filter_parts)
            logger.debug(f"Azure AI Search filter: {search_filter}")
            
            # Perform search with Azure AI Search
            search_results = await search_client.search(
                search_text=query,
                top=limit,
                search_fields=["content", "title"],
                select=["id", "title", "content", "document_id", "document_name", "metadata"],
                highlight_fields="content",
                filter=search_filter
            )
            
            results = []
            async for result in search_results:
                # Extract highlights
                highlights = []
                if hasattr(result, '@search.highlights') and result['@search.highlights']:
                    highlights = result['@search.highlights'].get('content', [])
                
                search_result = {
                    "id": result.get("id"),
                    "title": result.get("title", ""),
                    "content": result.get("content", ""),
                    "document_id": result.get("document_id"),
                    "document_name": result.get("document_name", ""),
                    "score": result.get("@search.score", 0.0),
                    "highlights": highlights,
                    "metadata": result.get("metadata", {})
                }
                results.append(search_result)
            
            logger.info(f"Found {len(results)} search results for query: {query}")
            if document_ids and len(document_ids) > 0:
                logger.info(f"Search was limited to {len(document_ids)} selected document(s)")
            if results:
                result_doc_ids = [r.get('document_id') for r in results]
                logger.debug(f"Results from documents: {result_doc_ids}")
            return results
            
        except Exception as e:
            logger.error(f"Azure AI Search error: {e}")
            # Fallback to simple search
            return await self._fallback_search(query, user_id, limit, document_ids)
    
    async def _generate_openai_response(
        self, 
        user_message: str, 
        context: str, 
        conversation: List[Dict[str, str]],
        document_ids: Optional[List[str]] = None
    ) -> str:
        """Generate response using Azure OpenAI"""
        try:
            openai_client = await self.openai_client
            
            if not openai_client:
                logger.warning("Azure OpenAI not configured, using fallback")
                return await self._generate_fallback_openai_response(user_message, context)
            
            # Build system prompt
            document_context_note = ""
            if document_ids and len(document_ids) > 0:
                document_context_note = f"\n\nCRITICAL: The user has specifically selected {len(document_ids)} document(s) to search. You MUST answer based ONLY on information from these selected documents. The user has already chosen which documents to search - do NOT ask them to select documents or specify which document they mean."
            
            system_prompt = f"""You are an AI assistant for an enterprise document management system called Omnisearch. Your role is to help users find and understand information from their uploaded documents.

{document_context_note}

Context from documents:
{context}

IMPORTANT INSTRUCTIONS:
1. Answer the user's question based ONLY on the context provided above
2. If the context contains document content, analyze it and provide a helpful answer:
   - For general questions like "What is this document about?" or "Summarize this", provide a comprehensive summary based on ALL the content in the context
   - For specific questions, find and cite the relevant information
   - Always mention the document name(s) when providing information
3. If the context is empty or says "no relevant content found", this means:
   - The search didn't find matching content in the selected documents
   - The documents might still be processing/indexing
   - The question might need to be rephrased
   - The documents might not contain information about that topic
4. When no relevant information is found, provide a helpful response like: "I searched through the selected document(s) but couldn't find specific information about [topic]. The documents might not contain details about this topic, or they may still be processing. Try rephrasing your question or selecting different documents."
5. For general questions about document content (e.g., "What is this about?", "Summarize", "What does this document say?"):
   - If context is provided, analyze ALL the content and provide a comprehensive summary
   - Identify the main topics, themes, and key information
   - Structure your response clearly with the main points
   - DO NOT say you couldn't find information if context is provided - the context IS the document content
6. Be conversational, helpful, and professional
7. Always mention the document name when citing information
8. If documents were selected, NEVER ask "which document are you referring to" - the user has already selected specific documents
9. When context contains document content, that IS the information you need - use it to answer the question

Remember: If the context contains document content, that means the search found it - use that content to answer the question. Only say you couldn't find information if the context explicitly says "no relevant content found" or is empty."""
            
            # Build messages for the conversation
            messages = [{"role": "system", "content": system_prompt}]
            
            # Add conversation history (last 10 messages)
            for msg in conversation[-10:]:
                messages.append({
                    "role": msg["role"],
                    "content": msg["content"]
                })
            
            # Add current user message
            messages.append({"role": "user", "content": user_message})
            
            # Generate response using Azure OpenAI
            response = await openai_client.chat.completions.create(
                model=settings.AZURE_OPENAI_DEPLOYMENT_NAME,
                messages=messages,
                max_tokens=settings.MAX_TOKENS,
                temperature=settings.TEMPERATURE,
                top_p=settings.TOP_P,
                frequency_penalty=0,
                presence_penalty=0
            )
            
            ai_response = response.choices[0].message.content
            logger.info(f"Generated AI response using Azure OpenAI")
            return ai_response
            
        except Exception as e:
            logger.error(f"Azure OpenAI error: {e}")
            return await self._generate_fallback_openai_response(user_message, context)
    
    def _build_context_from_search(self, search_results: List[Dict[str, Any]], document_ids: Optional[List[str]] = None) -> str:
        """Build context string from search results"""
        if not search_results:
            if document_ids and len(document_ids) > 0:
                # Provide more helpful context when no results found
                return f"Search completed for {len(document_ids)} selected document(s), but no matching content was found for the query. This could mean: (1) the documents don't contain information about this topic, (2) the documents are still being processed/indexed, or (3) the query needs to be rephrased. Document IDs searched: {', '.join(document_ids[:3])}{'...' if len(document_ids) > 3 else ''}"
            return "No relevant documents found in your document library. The search returned no results for your query."
        
        context_parts = []
        for result in search_results:
            context_part = f"Document Name: {result['document_name']}\n"
            context_part += f"Document Content:\n{result['content']}\n"
            if result.get('metadata'):
                # Parse metadata if it's a string
                metadata = result['metadata']
                if isinstance(metadata, str):
                    try:
                        metadata = json.loads(metadata)
                    except:
                        metadata = {}
                if isinstance(metadata, dict) and metadata.get('page'):
                    context_part += f"Source: Page {metadata.get('page', 'N/A')}\n"
            context_parts.append(context_part)
        
        # Add a clear header when content is found
        if context_parts:
            return f"RELEVANT CONTENT FOUND IN SELECTED DOCUMENTS:\n\n" + "\n\n---\n\n".join(context_parts)
        
        return "\n---\n".join(context_parts)
    
    def _build_conversation_history(self, chat_history: List[ChatMessage]) -> List[Dict[str, str]]:
        """Build conversation history for AI context"""
        conversation = []
        
        # Get last 10 messages for context
        recent_messages = chat_history[-10:] if len(chat_history) > 10 else chat_history
        
        for message in recent_messages:
            conversation.append({
                "role": message.role,
                "content": message.content
            })
        
        return conversation
    
    def _extract_sources_from_search(self, search_results: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Extract document sources from search results"""
        sources = []
        
        for result in search_results:
            source = {
                "document_id": result["document_id"],
                "document_name": result["document_name"],
                "relevance_score": result["score"],
                "snippet": result["content"][:200] + "..." if len(result["content"]) > 200 else result["content"]
            }
            
            # Parse metadata if it's a string
            metadata = result.get("metadata", {})
            if isinstance(metadata, str):
                try:
                    metadata = json.loads(metadata)
                except:
                    metadata = {}
            
            if isinstance(metadata, dict) and metadata.get("page"):
                source["page_number"] = metadata["page"]
            
            sources.append(source)
        
        return sources
    
    async def extract_document_text(self, file_path: str, file_type: str) -> Optional[str]:
        """Extract text from document using Azure Document Intelligence"""
        try:
            # Handle plain text files directly
            if file_type == "text/plain":
                async with aiofiles.open(file_path, 'r', encoding='utf-8') as f:
                    content = await f.read()
                return content
            
            # Use Azure Document Intelligence for other file types
            # Debug: Check settings directly
            logger.info(f"Checking Document Intelligence settings - Endpoint: {settings.AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT}, API Key exists: {bool(settings.AZURE_DOCUMENT_INTELLIGENCE_API_KEY)}")
            document_client = await self.document_client
            
            if not document_client:
                logger.warning(f"Azure Document Intelligence not configured - Endpoint: {settings.AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT}, API Key: {'SET' if settings.AZURE_DOCUMENT_INTELLIGENCE_API_KEY else 'NOT SET'}")
                return await self._fallback_text_extraction(file_path, file_type)
            
            # Read file content
            async with aiofiles.open(file_path, 'rb') as f:
                file_content = await f.read()
            
            # Analyze document with Azure Document Intelligence
            poller = await document_client.begin_analyze_document(
                "prebuilt-read",  # Use prebuilt read model for general text extraction
                document=file_content
            )
            
            result = await poller.result()
            
            # Extract text content
            extracted_text = ""
            for page in result.pages:
                for line in page.lines:
                    extracted_text += line.content + "\n"
            
            logger.info(f"Extracted {len(extracted_text)} characters from {file_type} document")
            return extracted_text.strip()
            
        except Exception as e:
            logger.error(f"Azure Document Intelligence error: {e}")
            return await self._fallback_text_extraction(file_path, file_type)
    
    async def create_document_embeddings(self, text_content: str) -> Optional[List[float]]:
        """Create embeddings for document text using Azure OpenAI"""
        try:
            openai_client = await self.openai_client
            
            if not openai_client:
                logger.warning("Azure OpenAI not configured for embeddings")
                return None
            
            # Create embeddings using Azure OpenAI
            response = await openai_client.embeddings.create(
                model="text-embedding-ada-002",  # Use the embeddings model
                input=text_content[:8000]  # Limit text length for embeddings
            )
            
            embeddings = response.data[0].embedding
            logger.info(f"Created embeddings with {len(embeddings)} dimensions")
            return embeddings
            
        except Exception as e:
            logger.error(f"Azure OpenAI embeddings error: {e}")
            return None
    
    async def index_document_in_search(
        self, 
        document_id: str, 
        title: str, 
        content: str, 
        metadata: Dict[str, Any],
        user_id: str
    ) -> bool:
        """Index document in Azure AI Search"""
        try:
            search_client = await self.search_client
            
            if not search_client:
                logger.warning("Azure AI Search not configured")
                return False
            
            # Create embeddings for the content
            embeddings = await self.create_document_embeddings(content)
            
            # Prepare document for indexing
            search_document = {
                "id": document_id,
                "title": title,
                "content": content,
                "document_id": document_id,
                "document_name": title,
                "user_id": user_id,
                "metadata": json.dumps(metadata) if metadata else "{}",
                "created_at": datetime.utcnow().isoformat(),
                "content_vector": embeddings  # Vector field for semantic search
            }
            
            # Upload document to search index
            result = await search_client.upload_documents([search_document])
            
            success = len(result) > 0 and result[0].succeeded
            if success:
                logger.info(f"Document indexed in Azure AI Search: {document_id}")
            else:
                logger.error(f"Failed to index document: {document_id}")
            
            return success
            
        except Exception as e:
            logger.error(f"Azure AI Search indexing error: {e}")
            return False    
            
    async def _fallback_search(self, query: str, user_id: str, limit: int, document_ids: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """Fallback search when Azure AI Search is not available"""
        logger.warning("Azure AI Search not available - returning empty results")
        # Return empty results
        return []
    
    async def _generate_fallback_openai_response(self, user_message: str, context: str) -> str:
        """Fallback response generation when Azure OpenAI is not available"""
        if "hello" in user_message.lower() or "hi" in user_message.lower():
            return "Hello! I'm your AI assistant. I can help you find information in your uploaded documents and answer questions based on them. Please upload some documents first, then ask me questions about their content."
        
        else:
            # Check if context indicates no results from selected documents
            if "No relevant content found in the selected" in context:
                return f"I searched through the selected document(s) but couldn't find information related to your question about '{user_message}'. The selected documents may not contain the information you're looking for. You might want to try selecting different documents or ask a different question."
            elif "No relevant documents found" in context:
                return f"I couldn't find relevant information in your documents about '{user_message}'. Based on the available context, I can help you with questions about company policies, procedures, and other document content. Could you provide more specific details about what you're looking for, or try selecting different documents?"
            else:
                return f"Based on the information in your selected documents, I found some context about '{user_message}'. However, I may not have all the details. Please review the document sources provided below for more complete information."
    
    async def _generate_fallback_response(self, user_message: str) -> Dict[str, Any]:
        """Generate fallback response when all Azure services fail"""
        return {
            "content": "I apologize, but I'm having trouble accessing the AI services right now. Please try again later, or contact support if the issue persists.",
            "sources": []
        }
    
    async def _fallback_text_extraction(self, file_path: str, file_type: str) -> Optional[str]:
        """Fallback text extraction when Azure Document Intelligence is not available"""
        try:
            if file_type == "application/pdf":
                # Try to use PyPDF2 as fallback (would need to be installed)
                return "Text extraction from PDF requires Azure Document Intelligence service to be configured."
            elif file_type in ["application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]:
                return "Text extraction from Word documents requires Azure Document Intelligence service to be configured."
            else:
                return "Text extraction for this file type requires Azure Document Intelligence service to be configured."
        except Exception as e:
            logger.error(f"Fallback text extraction error: {e}")
            return None