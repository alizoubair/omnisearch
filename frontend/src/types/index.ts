import { DefaultSession } from 'next-auth'

// Extend NextAuth session type
declare module 'next-auth' {
  interface Session extends DefaultSession {
    user: {
      id: string
      name?: string | null
      email?: string | null
      image?: string | null
    }
  }
}

// Document types
export interface Document {
  id: string
  name: string
  type: string
  size: number
  uploadedAt: string
  status: 'uploading' | 'processing' | 'ready' | 'error'
  url?: string
  metadata?: {
    pages?: number
    language?: string
    tags?: string[]
  }
}

// Chat types
export interface ChatMessage {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: string
  sources?: DocumentSource[]
}

export interface DocumentSource {
  documentId: string
  documentName: string
  pageNumber?: number
  relevanceScore: number
  snippet: string
}

export interface ChatSession {
  id: string
  title: string
  messages: ChatMessage[]
  createdAt: string
  updatedAt: string
}

// Search types
export interface SearchResult {
  id: string
  title: string
  content: string
  documentId: string
  documentName: string
  score: number
  highlights?: string[]
  metadata?: Record<string, any>
}

export interface SearchFilters {
  documentTypes?: string[]
  dateRange?: {
    from: string
    to: string
  }
  tags?: string[]
}

// Upload types
export interface UploadProgress {
  fileId: string
  fileName: string
  progress: number
  status: 'uploading' | 'processing' | 'completed' | 'error'
  error?: string
}

// API Response types
export interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
  message?: string
}

export interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  pageSize: number
  hasMore: boolean
}