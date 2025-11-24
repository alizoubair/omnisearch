import { ChatMessage, ChatSession, ApiResponse, SearchResult } from '@/types'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || ''

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message)
    this.name = 'ApiError'
  }
}

// Token management
let cachedToken: string | null = null

// Export function to clear cache (call on sign out)
export function clearApiCache() {
  cachedToken = null
  currentUserId = null
  console.log('API cache cleared')
}

// Track current user to detect user changes
let currentUserId: string | null = null

async function getAuthToken(): Promise<string | null> {
  if (typeof window !== 'undefined') {
    try {
      // Get session from NextAuth
      console.log('Fetching NextAuth session...')
      const session = await fetch('/api/auth/session').then(res => res.json())
      console.log('NextAuth session:', session)

      // Check if user changed
      const sessionUserId = session?.user?.id || session?.user?.email
      if (sessionUserId && currentUserId && sessionUserId !== currentUserId) {
        console.log('User changed, clearing cache')
        cachedToken = null
        currentUserId = sessionUserId

        // Clear React Query cache on user change
        if (typeof window !== 'undefined' && (window as any).queryClient) {
          (window as any).queryClient.clear()
        }
      } else if (sessionUserId) {
        currentUserId = sessionUserId
      }

      // Use cached token if available and user hasn't changed
      if (cachedToken) {
        console.log('Using cached token')
        return cachedToken
      }

      // NextAuth already has the access token from login
      if (session?.accessToken) {
        console.log('Using access token from NextAuth session')
        cachedToken = session.accessToken
        return cachedToken
      }

      // Fallback: If no token in session, user needs to sign in
      console.log('No access token in session - user needs to sign in')
    } catch (error) {
      console.error('Failed to get auth token:', error)
    }
  }

  return null
}

async function apiRequest<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const url = `${API_BASE_URL}${endpoint}`

  // Get authentication token
  const token = await getAuthToken()
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  }

  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  // Merge with any additional headers from options
  if (options.headers) {
    Object.assign(headers, options.headers)
  }

  const response = await fetch(url, {
    ...options,
    headers,
  })

  // Handle empty responses (204 No Content, 205 Reset Content)
  if (response.status === 204 || response.status === 205 || response.headers.get('content-length') === '0') {
    if (!response.ok) {
      throw new ApiError(response.status, 'Request failed')
    }
    return undefined as T
  }

  // Parse JSON response
  const text = await response.text()
  const data = text ? JSON.parse(text) : {}

  if (!response.ok) {
    // If unauthorized, clear cached token and retry once
    if (response.status === 401 && cachedToken) {
      cachedToken = null
      return apiRequest(endpoint, options)
    }

    // Don't log 404 errors for DELETE requests (expected behavior)
    if (!(response.status === 404 && options.method === 'DELETE')) {
      console.error(`API Error ${response.status}:`, endpoint, data)
    }

    throw new ApiError(response.status, data.error || data.detail || 'An error occurred')
  }

  return data
}

// Helper function to transform snake_case to camelCase
function toCamelCase(obj: any): any {
  if (Array.isArray(obj)) {
    return obj.map(toCamelCase)
  }

  if (obj !== null && typeof obj === 'object') {
    return Object.keys(obj).reduce((acc, key) => {
      const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase())
      acc[camelKey] = toCamelCase(obj[key])
      return acc
    }, {} as any)
  }

  return obj
}

// Chat API functions
export const chatApi = {
  // Send a message and get AI response
  sendMessage: async (message: string, sessionId: string, documentIds?: string[]): Promise<ChatMessage> => {
    try {
      const requestBody: any = { message, sessionId }
      if (documentIds && documentIds.length > 0) {
        requestBody.documentIds = documentIds
      }

      const response = await fetch('/api/chat/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
        signal: AbortSignal.timeout(60000), // 60 second timeout for AI responses
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.error || `Failed to send message: ${response.statusText}`)
      }

      const data = await response.json()
      // Handle both response formats: { message: {...} } or direct message object
      const messageData = data.message || data
      const transformed = toCamelCase(messageData)
      
      // Ensure timestamp exists
      if (!transformed.timestamp) {
        transformed.timestamp = new Date().toISOString()
      }
      
      return transformed
    } catch (error: any) {
      console.error('Error sending chat message:', error)
      throw error
    }
  },

  // Get all chat sessions for the user
  getSessions: async (): Promise<ChatSession[]> => {
    try {
      const response = await fetch('/api/chat/sessions', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        signal: AbortSignal.timeout(30000), // 30 second timeout
      })

      if (!response.ok) {
        const error = await response.text()
        console.error('Error fetching chat sessions:', response.status, error)
        return []
      }

      const data = await response.json()
      const transformed = toCamelCase(data)
      // Ensure each session has messages array
      return transformed.map((session: any) => ({
        ...session,
        messages: session.messages || []
      }))
    } catch (error: any) {
      console.error('Error fetching chat sessions:', error)
      // Return empty array on error instead of throwing
      return []
    }
  },

  // Create a new chat session
  createSession: async (title?: string): Promise<ChatSession> => {
    try {
      const response = await fetch('/api/chat/sessions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ title: title || 'New Chat' }),
        signal: AbortSignal.timeout(30000), // 30 second timeout
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.error || `Failed to create chat session: ${response.statusText}`)
      }

      const data = await response.json()
      const transformed = toCamelCase(data)
      // Ensure messages array exists
      if (!transformed.messages) {
        transformed.messages = []
      }
      return transformed
    } catch (error: any) {
      console.error('Error creating chat session:', error)
      throw error
    }
  },

  // Get a specific chat session
  getSession: async (sessionId: string): Promise<ChatSession> => {
    try {
      const response = await fetch(`/api/chat/sessions/${sessionId}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        signal: AbortSignal.timeout(30000), // 30 second timeout
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.error || `Failed to fetch chat session: ${response.statusText}`)
      }

      const data = await response.json()
      const transformed = toCamelCase(data)
      // Ensure messages array exists
      if (!transformed.messages) {
        transformed.messages = []
      }
      return transformed
    } catch (error: any) {
      console.error('Error fetching chat session:', error)
      throw error
    }
  },

  // Delete a chat session
  deleteSession: async (sessionId: string): Promise<void> => {
    try {
      const response = await fetch(`/api/chat/sessions/${sessionId}`, {
        method: 'DELETE',
        signal: AbortSignal.timeout(30000), // 30 second timeout
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.error || `Failed to delete chat session: ${response.statusText}`)
      }
    } catch (error: any) {
      console.error('Error deleting chat session:', error)
      throw error
    }
  },
}

// Document API functions
export const documentApi = {
  // Upload a document
  uploadDocument: async (file: File): Promise<any> => {
    const formData = new FormData()
    formData.append('file', file)

    const response = await fetch(`${API_BASE_URL}/api/documents/upload`, {
      method: 'POST',
      body: formData,
    })

    return response.json()
  },

  // Get all documents
  getDocuments: async (): Promise<any[]> => {
    try {
      const response = await fetch('/api/documents', {
        signal: AbortSignal.timeout(30000), // 30 second timeout
      })
      
      if (!response.ok) {
        console.error('Failed to fetch documents:', response.status, response.statusText)
        return []
      }
      
      const documents = await response.json()
      
      // Ensure we have an array
      if (!Array.isArray(documents)) {
        console.error('Documents API did not return an array:', documents)
        return []
      }
      
      return toCamelCase(documents) || []
    } catch (error: any) {
      console.error('Error fetching documents:', error)
      // Return empty array on error to prevent hanging
      return []
    }
  },

  // Delete a document
  deleteDocument: async (documentId: string): Promise<void> => {
    try {
      const response = await fetch(`/api/documents/${documentId}`, {
        method: 'DELETE',
        signal: AbortSignal.timeout(30000), // 30 second timeout
      })
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.error || `Failed to delete document: ${response.statusText}`)
      }
    } catch (error: any) {
      console.error('Error deleting document:', error)
      // Re-throw to allow caller to handle
      throw error
    }
  },
}

// Search API functions
export const searchApi = {
  // Search documents using AI-powered semantic search
  searchDocuments: async (query: string, limit: number = 10, offset: number = 0, filters?: any): Promise<SearchResult[]> => {
    const response = await apiRequest<any[]>('/api/v1/search/documents', {
      method: 'POST',
      body: JSON.stringify({ query, limit, offset, filters }),
    })

    return toCamelCase(response) || []
  },

  // Simple keyword-based document search
  searchDocumentsSimple: async (query: string, limit: number = 10, offset: number = 0): Promise<SearchResult[]> => {
    const params = new URLSearchParams({
      q: query,
      limit: limit.toString(),
      offset: offset.toString(),
    })
    const response = await apiRequest<any[]>(`/api/v1/search/documents/simple?${params.toString()}`)

    return toCamelCase(response) || []
  },
}

export { ApiError }