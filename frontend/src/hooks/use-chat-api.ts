import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { chatApi } from '@/lib/api'
import { ChatSession, ChatMessage } from '@/types'
import { useToast } from '@/hooks/use-toast'

// Query keys
export const chatKeys = {
  all: ['chat'] as const,
  sessions: () => [...chatKeys.all, 'sessions'] as const,
  session: (id: string) => [...chatKeys.all, 'session', id] as const,
}

// Get all chat sessions
export function useChatSessions() {
  return useQuery({
    queryKey: chatKeys.sessions(),
    queryFn: chatApi.getSessions,
    staleTime: 30 * 1000, // 30 seconds - shorter to keep in sync
    refetchOnWindowFocus: true, // Refetch when user returns to tab
    refetchOnMount: true, // Always refetch on mount
    gcTime: 0, // Don't cache after unmount - always fetch fresh
  })
}

// Get specific chat session
export function useChatSession(sessionId: string | null) {
  return useQuery({
    queryKey: chatKeys.session(sessionId || ''),
    queryFn: () => sessionId ? chatApi.getSession(sessionId) : null,
    enabled: !!sessionId,
    staleTime: 1 * 60 * 1000, // 1 minute
  })
}

// Create new chat session
export function useCreateChatSession() {
  const queryClient = useQueryClient()
  const { toast } = useToast()

  return useMutation({
    mutationFn: chatApi.createSession,
    onSuccess: (newSession) => {
      // Update sessions cache with the new session
      queryClient.setQueryData(chatKeys.sessions(), (old: ChatSession[] = []) => {
        // Ensure we don't duplicate if it already exists
        const filtered = old.filter(s => s.id !== newSession.id)
        return [newSession, ...filtered]
      })

      // Also set the individual session cache
      queryClient.setQueryData(chatKeys.session(newSession.id), newSession)

      toast({
        title: "New Chat Created",
        description: "Started a new conversation"
      })
    },
    onError: () => {
      toast({
        title: "Error",
        description: "Failed to create new chat session",
        variant: "destructive"
      })
    },
  })
}

// Send message
export function useSendMessage() {
  const queryClient = useQueryClient()
  const { toast } = useToast()

  return useMutation({
    mutationFn: ({ message, sessionId, documentIds }: { message: string; sessionId: string; documentIds?: string[] }) =>
      chatApi.sendMessage(message, sessionId, documentIds),
    onSuccess: (_, { sessionId }) => {
      // Invalidate and refetch the session to get updated messages
      queryClient.invalidateQueries({ queryKey: chatKeys.session(sessionId) })
      queryClient.invalidateQueries({ queryKey: chatKeys.sessions() })
    },
    onError: () => {
      toast({
        title: "Error",
        description: "Failed to send message. Please try again.",
        variant: "destructive"
      })
    },
  })
}

// Delete chat session
export function useDeleteChatSession() {
  const queryClient = useQueryClient()
  const { toast } = useToast()

  return useMutation({
    mutationFn: chatApi.deleteSession,
    onSuccess: (_, sessionId) => {
      // Remove from sessions cache immediately for instant UI update
      queryClient.setQueryData(chatKeys.sessions(), (old: ChatSession[] = []) =>
        old.filter(session => session.id !== sessionId)
      )

      // Remove session cache
      queryClient.removeQueries({ queryKey: chatKeys.session(sessionId) })

      // Also invalidate to trigger refetch and ensure sync
      queryClient.invalidateQueries({ queryKey: chatKeys.sessions() })

      toast({
        title: "Chat Deleted",
        description: "Chat session has been deleted"
      })
    },
    onError: (error: any, sessionId) => {
      // If 404, the session was already deleted or doesn't belong to user
      if (error?.status === 404) {
        queryClient.setQueryData(chatKeys.sessions(), (old: ChatSession[] = []) =>
          old.filter(session => session.id !== sessionId)
        )
        queryClient.removeQueries({ queryKey: chatKeys.session(sessionId) })

        // Refetch to get fresh list from server
        queryClient.invalidateQueries({ queryKey: chatKeys.sessions() })

        toast({
          title: "Chat Removed",
          description: "Chat session was already deleted or not accessible"
        })
      } else {
        toast({
          title: "Error",
          description: "Failed to delete chat session",
          variant: "destructive"
        })
      }
    },
  })
}