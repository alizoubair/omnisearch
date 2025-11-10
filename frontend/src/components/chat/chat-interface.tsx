'use client'

import { useState, useRef, useEffect } from 'react'
import { Send, Bot, User, FileText, Loader2, Trash2, X, Filter } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover'
import { Checkbox } from '@/components/ui/checkbox'
import { useToast } from '@/hooks/use-toast'
import { formatDate, generateId } from '@/lib/utils'
import {
  useChatSessions,
  useChatSession,
  useCreateChatSession,
  useSendMessage,
  useDeleteChatSession
} from '@/hooks/use-chat-api'
import { ChatMessage, DocumentSource } from '@/types'

export function ChatInterface() {
  const [message, setMessage] = useState('')
  const [currentSessionId, setCurrentSessionId] = useState<string | null>(null)
  const [selectedDocuments, setSelectedDocuments] = useState<string[]>([])
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  const { toast } = useToast()

  // API hooks
  const { data: sessions = [], isLoading: sessionsLoading } = useChatSessions()
  const { data: currentSession, isLoading: currentSessionLoading } = useChatSession(currentSessionId)
  const createSessionMutation = useCreateChatSession()
  const sendMessageMutation = useSendMessage()
  const deleteSessionMutation = useDeleteChatSession()

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [currentSession?.messages])

  // Listen for new chat events from sidebar
  useEffect(() => {
    const handleNewChat = () => {
      setCurrentSessionId(null)
      setSelectedDocuments([])
      setMessage('')
    }

    window.addEventListener('newChat', handleNewChat)
    return () => window.removeEventListener('newChat', handleNewChat)
  }, [])

  const handleSendMessage = async () => {
    if (!message.trim() || sendMessageMutation.isPending) return

    const userMessage: ChatMessage = {
      id: generateId(),
      role: 'user',
      content: message.trim(),
      timestamp: new Date().toISOString()
    }

    // Clear input immediately
    setMessage('')

    try {
      let sessionId = currentSessionId

      // Create a new session if none exists
      if (!sessionId) {
        const newSession = await createSessionMutation.mutateAsync(undefined)
        sessionId = newSession.id
        setCurrentSessionId(sessionId)
      }

      // Send message and get AI response (this also adds the user message)
      const documentIdsToSend = selectedDocuments.length > 0 ? selectedDocuments : undefined
      if (documentIdsToSend) {
        console.log('Sending chat message with selected documents:', documentIdsToSend)
      }
      await sendMessageMutation.mutateAsync({
        message: userMessage.content,
        sessionId: sessionId,
        documentIds: documentIdsToSend
      })

    } catch (error) {
      console.error('Failed to send message:', error)
      toast({
        title: "Error",
        description: "Failed to send message. Please try again.",
        variant: "destructive"
      })
    }
  }

  const handleDeleteSession = async (sessionId: string) => {
    try {
      // Delete the session first
      await deleteSessionMutation.mutateAsync(sessionId)

      // After successful delete, if we deleted the current session, switch to another one
      if (sessionId === currentSessionId) {
        // Use updated sessions list from cache
        const updatedSessions = sessions.filter(s => s.id !== sessionId)
        if (updatedSessions.length > 0) {
          setCurrentSessionId(updatedSessions[0].id)
        } else {
          setCurrentSessionId(null)
        }
      }
    } catch (error) {
      // Error is already handled by the mutation
      console.error('Failed to delete session:', error)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSendMessage()
    }
  }

  if (sessionsLoading) {
    return (
      <Card className="h-full flex items-center justify-center">
        <CardContent>
          <div className="text-center">
            <Loader2 className="h-8 w-8 mx-auto mb-4 animate-spin" />
            <p className="text-muted-foreground">Loading chat sessions...</p>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="h-full flex">
      {/* Sidebar with chat sessions */}
      <div className="w-80 border-r bg-muted/20">
        <div className="p-4 border-b">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-lg font-semibold">History</h2>
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                setCurrentSessionId(null)
                setSelectedDocuments([])
                setMessage('')
              }}
              className="h-8 px-3"
            >
              New Chat
            </Button>
          </div>
          <p className="text-sm text-muted-foreground">Your chat sessions</p>
        </div>

        <div className="overflow-y-auto h-full pb-20">
          {sessions.length === 0 ? (
            <div className="p-4 text-center text-muted-foreground">
              <p className="text-sm">No chat history yet</p>
              <p className="text-xs mt-1">Start a conversation to see it here</p>
            </div>
          ) : (
            sessions.map((session) => (
              <div
                key={session.id}
                className={`p-3 border-b cursor-pointer hover:bg-muted/50 transition-colors ${session.id === currentSessionId ? 'bg-muted' : ''
                  }`}
                onClick={() => setCurrentSessionId(session.id)}
              >
                <div className="flex items-center justify-between">
                  <div className="flex-1 min-w-0">
                    <h4 className="font-medium truncate">{session.title}</h4>
                    <p className="text-xs text-muted-foreground">
                      {formatDate(session.updatedAt)}
                    </p>
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={(e) => {
                      e.stopPropagation()
                      handleDeleteSession(session.id)
                    }}
                    disabled={deleteSessionMutation.isPending}
                    className="h-8 w-8 p-0"
                  >
                    <Trash2 className="h-3 w-3" />
                  </Button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Main chat area */}
      <Card className="flex-1 flex flex-col overflow-hidden">
        <CardHeader className="border-b flex-shrink-0">
          <CardTitle className="flex items-center space-x-2">
            <Bot className="h-5 w-5" />
            <span>AI Assistant</span>
          </CardTitle>
        </CardHeader>

        <CardContent className="flex-1 flex flex-col p-0 overflow-hidden">
          {/* Messages Area */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4 custom-scrollbar min-h-0">
            {!currentSession || !currentSession.messages || currentSession.messages.length === 0 ? (
              <div className="text-center py-8">
                <Bot className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                <h3 className="text-lg font-semibold mb-2">Welcome to AI Assistant</h3>
                <p className="text-muted-foreground">
                  Ask me anything about your uploaded documents. I can help you find information,
                  summarize content, and answer questions based on your document library.
                </p>
              </div>
            ) : (
              currentSession.messages.map((msg) => (
                <MessageBubble key={msg.id} message={msg} />
              ))
            )}

            {/* Loading indicator */}
            {sendMessageMutation.isPending && (
              <div className="flex items-start space-x-3">
                <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center">
                  <Bot className="h-4 w-4 text-primary-foreground" />
                </div>
                <div className="bg-muted p-3 rounded-lg max-w-xs">
                  <div className="flex items-center space-x-1">
                    <Loader2 className="h-4 w-4 animate-spin" />
                    <span className="text-sm text-muted-foreground">AI is thinking...</span>
                  </div>
                </div>
              </div>
            )}

            <div ref={messagesEndRef} />
          </div>

          {/* Input Area */}
          <div className="border-t p-4 flex-shrink-0">
            {/* Document Filter */}
            {selectedDocuments.length > 0 && (
              <div className="mb-3 flex flex-wrap gap-2">
                {selectedDocuments.map((docId) => (
                  <Badge key={docId} variant="secondary" className="flex items-center gap-1">
                    <FileText className="h-3 w-3" />
                    <span className="text-xs">Document {docId.slice(0, 8)}</span>
                    <button
                      onClick={() => setSelectedDocuments(prev => prev.filter(id => id !== docId))}
                      className="ml-1 hover:bg-muted rounded-full p-0.5"
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </Badge>
                ))}
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setSelectedDocuments([])}
                  className="h-6 text-xs"
                >
                  Clear all
                </Button>
              </div>
            )}

            <div className="flex space-x-2">
              <div className="flex-1 flex flex-col space-y-2">
                <div className="flex space-x-2">
                  <Textarea
                    ref={textareaRef}
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    onKeyDown={handleKeyDown}
                    placeholder={
                      selectedDocuments.length > 0
                        ? `Ask about ${selectedDocuments.length} selected document${selectedDocuments.length > 1 ? 's' : ''}...`
                        : "Ask me anything about your documents..."
                    }
                    className="min-h-[60px] resize-none"
                    disabled={sendMessageMutation.isPending}
                  />
                  <div className="flex flex-col space-y-2">
                    <DocumentSelector
                      selectedDocuments={selectedDocuments}
                      onSelectDocuments={setSelectedDocuments}
                    />
                    <Button
                      onClick={handleSendMessage}
                      disabled={!message.trim() || sendMessageMutation.isPending}
                      size="icon"
                      className="h-[60px] w-[60px]"
                    >
                      <Send className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </div>
            </div>
            <p className="text-xs text-muted-foreground mt-2">
              {selectedDocuments.length > 0 ? (
                <>Searching in {selectedDocuments.length} document{selectedDocuments.length > 1 ? 's' : ''} • </>
              ) : (
                <>Searching all documents • </>
              )}
              Press Enter to send, Shift+Enter for new line
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

interface MessageBubbleProps {
  message: ChatMessage
}

function MessageBubble({ message }: MessageBubbleProps) {
  const isUser = message.role === 'user'

  return (
    <div className={`flex items-start space-x-3 ${isUser ? 'flex-row-reverse space-x-reverse' : ''}`}>
      {/* Avatar */}
      <div className={`w-8 h-8 rounded-full flex items-center justify-center ${isUser ? 'bg-blue-500' : 'bg-primary'
        }`}>
        {isUser ? (
          <User className="h-4 w-4 text-white" />
        ) : (
          <Bot className="h-4 w-4 text-primary-foreground" />
        )}
      </div>

      {/* Message Content */}
      <div className={`flex-1 max-w-[80%] ${isUser ? 'text-right' : ''}`}>
        <div className={`p-3 rounded-lg ${isUser
          ? 'bg-blue-500 text-white ml-auto'
          : 'bg-muted'
          }`}>
          <p className="text-sm whitespace-pre-wrap">{message.content}</p>
        </div>

        {/* Sources */}
        {message.sources && message.sources.length > 0 && (
          <div className="mt-2 space-y-2">
            <p className="text-xs text-muted-foreground font-medium">Sources:</p>
            {message.sources.map((source, index) => (
              <SourceCard key={index} source={source} />
            ))}
          </div>
        )}

        {/* Timestamp */}
        <p className="text-xs text-muted-foreground mt-1">
          {formatDate(message.timestamp)}
        </p>
      </div>
    </div>
  )
}

interface SourceCardProps {
  source: DocumentSource
}

function SourceCard({ source }: SourceCardProps) {
  return (
    <div className="bg-background border rounded-lg p-3 text-sm">
      <div className="flex items-center space-x-2 mb-2">
        <FileText className="h-4 w-4 text-muted-foreground" />
        <span className="font-medium">{source.documentName}</span>
        {source.pageNumber && (
          <span className="text-muted-foreground">• Page {source.pageNumber}</span>
        )}
        <span className="text-muted-foreground">• {Math.round(source.relevanceScore * 100)}% match</span>
      </div>
      <p className="text-muted-foreground italic">"{source.snippet}"</p>
    </div>
  )
}

interface DocumentSelectorProps {
  selectedDocuments: string[]
  onSelectDocuments: (documents: string[]) => void
}

function DocumentSelector({ selectedDocuments, onSelectDocuments }: DocumentSelectorProps) {
  const [documents, setDocuments] = useState<Array<{ id: string; name: string }>>([])
  const [isLoading, setIsLoading] = useState(true)

  // Fetch real documents from API
  useEffect(() => {
    const fetchDocuments = async () => {
      try {
        setIsLoading(true)
        const { documentApi } = await import('@/lib/api')
        const docs = await documentApi.getDocuments()

        // Transform to expected format
        const formattedDocs = docs.map((doc: any) => ({
          id: doc.id || doc.documentId,
          name: doc.name || doc.fileName || doc.title || 'Untitled Document'
        }))

        setDocuments(formattedDocs)
      } catch (error) {
        console.error('Failed to fetch documents:', error)
        setDocuments([])
      } finally {
        setIsLoading(false)
      }
    }

    fetchDocuments()
  }, [])

  const toggleDocument = (docId: string) => {
    if (selectedDocuments.includes(docId)) {
      onSelectDocuments(selectedDocuments.filter(id => id !== docId))
    } else {
      onSelectDocuments([...selectedDocuments, docId])
    }
  }

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          size="icon"
          className="h-[60px] w-[60px] relative"
          title="Filter documents"
        >
          <Filter className="h-4 w-4" />
          {selectedDocuments.length > 0 && (
            <Badge
              variant="destructive"
              className="absolute -top-1 -right-1 h-5 w-5 rounded-full p-0 flex items-center justify-center text-xs"
            >
              {selectedDocuments.length}
            </Badge>
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-80" align="end">
        <div className="space-y-4">
          <div className="space-y-2">
            <h4 className="font-medium text-sm">Filter by Documents</h4>
            <p className="text-xs text-muted-foreground">
              Select specific documents to search. Leave empty to search all.
            </p>
          </div>
          <div className="space-y-2 max-h-[300px] overflow-y-auto">
            {isLoading ? (
              <div className="text-center py-4 text-sm text-muted-foreground">
                Loading documents...
              </div>
            ) : documents.length === 0 ? (
              <div className="text-center py-4 text-sm text-muted-foreground">
                No documents available
              </div>
            ) : (
              documents.map((doc) => (
                <div key={doc.id} className="flex items-center space-x-2">
                  <Checkbox
                    id={doc.id}
                    checked={selectedDocuments.includes(doc.id)}
                    onCheckedChange={() => toggleDocument(doc.id)}
                  />
                  <label
                    htmlFor={doc.id}
                    className="text-sm flex-1 cursor-pointer flex items-center space-x-2"
                  >
                    <FileText className="h-4 w-4 text-muted-foreground" />
                    <span>{doc.name}</span>
                  </label>
                </div>
              ))
            )}
          </div>
          {selectedDocuments.length > 0 && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => onSelectDocuments([])}
              className="w-full"
            >
              Clear Selection
            </Button>
          )}
        </div>
      </PopoverContent>
    </Popover>
  )
}