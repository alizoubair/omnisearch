#!/usr/bin/env python3
"""
Script to create Azure AI Search index for Omnisearch
"""
import os
import sys
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
    SearchIndex,
    SimpleField,
    SearchFieldDataType,
    SearchableField,
    VectorSearch,
    VectorSearchAlgorithmConfiguration,
    HnswAlgorithmConfiguration,
    VectorSearchProfile,
    SemanticConfiguration,
    SemanticPrioritizedFields,
    SemanticField,
    PrioritizedFields
)

# Get credentials from environment
from azure.core.credentials import AzureKeyCredential

def create_index():
    """Create the Azure AI Search index"""
    # Try to get from app settings first, then fall back to environment variables
    endpoint = None
    api_key = None
    index_name = 'ai-foundry-documents'
    
    try:
        # Try to import from app settings
        sys.path.insert(0, '/app')
        from app.core.config import settings
        endpoint = settings.AZURE_SEARCH_ENDPOINT
        api_key = settings.AZURE_SEARCH_API_KEY
        index_name = settings.AZURE_SEARCH_INDEX_NAME
    except:
        # Fall back to environment variables
        endpoint = os.environ.get('AZURE_SEARCH_ENDPOINT') or os.environ.get('AI_SEARCH_ENDPOINT')
        api_key = os.environ.get('AZURE_SEARCH_API_KEY') or os.environ.get('AI_SEARCH_KEY')
        index_name = os.environ.get('AZURE_SEARCH_INDEX_NAME', 'ai-foundry-documents')
    
    if not endpoint or not api_key:
        print("⚠️ Azure AI Search not configured (endpoint or API key missing), skipping index creation")
        print(f"   Endpoint: {'SET' if endpoint else 'NOT SET'}")
        print(f"   API Key: {'SET' if api_key else 'NOT SET'}")
        sys.exit(0)  # Don't fail, just skip
    
    # Create search index client
    client = SearchIndexClient(endpoint=endpoint, credential=AzureKeyCredential(api_key))
    
    # Define the index
    index = SearchIndex(
        name=index_name,
        fields=[
            SimpleField(name="id", type=SearchFieldDataType.String, key=True),
            SearchableField(name="title", type=SearchFieldDataType.String, searchable=True, filterable=True),
            SearchableField(name="content", type=SearchFieldDataType.String, searchable=True),
            SimpleField(name="document_id", type=SearchFieldDataType.String, filterable=True),
            SearchableField(name="document_name", type=SearchFieldDataType.String, searchable=True, filterable=True),
            SimpleField(name="user_id", type=SearchFieldDataType.String, filterable=True),
            SimpleField(name="metadata", type=SearchFieldDataType.String),
            SimpleField(name="created_at", type=SearchFieldDataType.String, filterable=True, sortable=True),
            # Vector field for embeddings (1536 dimensions for text-embedding-ada-002)
            SimpleField(
                name="content_vector",
                type=SearchFieldDataType.Collection(SearchFieldDataType.Single),
                vector_search_dimensions=1536,
                vector_search_profile_name="my-vector-profile"
            )
        ],
        vector_search=VectorSearch(
            algorithms=[
                VectorSearchAlgorithmConfiguration(
                    name="my-hnsw-config",
                    kind="hnsw",
                    parameters=HnswAlgorithmConfiguration(
                        m=4,
                        ef_construction=400,
                        ef_search=500,
                        metric="cosine"
                    )
                )
            ],
            profiles=[
                VectorSearchProfile(
                    name="my-vector-profile",
                    algorithm="my-hnsw-config"
                )
            ]
        ),
        semantic_configurations=[
            SemanticConfiguration(
                name="default",
                prioritized_fields=SemanticPrioritizedFields(
                    title_field=SemanticField(field_name="title"),
                    content_fields=[SemanticField(field_name="content")]
                )
            )
        ]
    )
    
    try:
        # Check if index already exists
        try:
            existing_index = client.get_index(index_name)
            print(f"Index '{index_name}' already exists. Deleting and recreating...")
            client.delete_index(index_name)
        except Exception:
            print(f"Index '{index_name}' does not exist. Creating new index...")
        
        # Create the index
        result = client.create_index(index)
        print(f"✅ Successfully created index '{index_name}'")
        print(f"   Fields: {len(result.fields)}")
        print(f"   Vector search: Enabled")
        print(f"   Semantic search: Enabled")
        return True
        
    except Exception as e:
        print(f"❌ Error creating index: {e}")
        return False

if __name__ == "__main__":
    success = create_index()
    sys.exit(0 if success else 1)

