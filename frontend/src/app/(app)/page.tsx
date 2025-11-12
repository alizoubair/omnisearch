'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { MessageSquare, FileText, Search, Upload, Bot, Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { useToast } from '@/hooks/use-toast'

interface DashboardStats {
  totalDocuments: number
  searchesToday: number
  chatSessions: number
  recentUploads: number
}

interface RecentActivity {
  id: string
  type: 'search' | 'upload' | 'chat'
  title: string
  description: string
  timestamp: string
}

export default function HomePage() {
  const router = useRouter()
  const { toast } = useToast()
  const [stats, setStats] = useState<DashboardStats>({
    totalDocuments: 0,
    searchesToday: 0,
    chatSessions: 0,
    recentUploads: 0
  })
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([])
  const [isLoading, setIsLoading] = useState(true)

  // Fetch real dashboard data
  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setIsLoading(true)

        // Fetch documents count
        const { documentApi } = await import('@/lib/api')
        const documents = await documentApi.getDocuments()

        // Fetch chat sessions count
        const { chatApi } = await import('@/lib/api')
        const sessions = await chatApi.getSessions()

        setStats({
          totalDocuments: documents.length,
          searchesToday: Math.floor(Math.random() * 50) + 10, // Mock for now
          chatSessions: sessions.length,
          recentUploads: documents.filter((doc: any) => {
            const uploadDate = new Date(doc.createdAt || doc.created_at)
            const today = new Date()
            const diffTime = Math.abs(today.getTime() - uploadDate.getTime())
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
            return diffDays <= 7
          }).length
        })

        // Create recent activity from real data
        const activities: RecentActivity[] = []

        // Add recent documents
        documents.slice(0, 3).forEach((doc: any, index: number) => {
          activities.push({
            id: `doc-${doc.id}`,
            type: 'upload',
            title: doc.name || doc.title || 'Untitled Document',
            description: 'Document uploaded',
            timestamp: doc.createdAt || doc.created_at || new Date().toISOString()
          })
        })

        // Add recent chat sessions
        sessions.slice(0, 2).forEach((session: any) => {
          activities.push({
            id: `chat-${session.id}`,
            type: 'chat',
            title: session.title || 'AI Chat Session',
            description: 'Chat conversation',
            timestamp: session.updatedAt || session.updated_at || new Date().toISOString()
          })
        })

        // Sort by timestamp
        activities.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
        setRecentActivity(activities.slice(0, 5))

      } catch (error) {
        console.error('Failed to fetch dashboard data:', error)
        toast({
          title: "Error",
          description: "Failed to load dashboard data",
          variant: "destructive"
        })
      } finally {
        setIsLoading(false)
      }
    }

    fetchDashboardData()
  }, [toast])

  const handleNewChat = () => {
    router.push('/chat')
    // Trigger new chat event after navigation
    setTimeout(() => {
      window.dispatchEvent(new CustomEvent('newChat'))
    }, 100)
  }

  const formatTimeAgo = (timestamp: string) => {
    const now = new Date()
    const time = new Date(timestamp)
    const diffInHours = Math.floor((now.getTime() - time.getTime()) / (1000 * 60 * 60))

    if (diffInHours < 1) return 'Just now'
    if (diffInHours < 24) return `${diffInHours}h ago`
    const diffInDays = Math.floor(diffInHours / 24)
    if (diffInDays < 7) return `${diffInDays}d ago`
    return time.toLocaleDateString()
  }

  const getActivityIcon = (type: string) => {
    switch (type) {
      case 'search': return <Search className="h-4 w-4" />
      case 'upload': return <FileText className="h-4 w-4" />
      case 'chat': return <MessageSquare className="h-4 w-4" />
      default: return <FileText className="h-4 w-4" />
    }
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Welcome back!</h1>
          <p className="text-muted-foreground">
            Your AI-powered document management dashboard
          </p>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="cursor-pointer hover:shadow-md transition-shadow" onClick={handleNewChat}>
          <CardContent className="flex items-center p-6">
            <div className="p-2 bg-blue-100 rounded-lg mr-4">
              <Bot className="h-6 w-6 text-blue-600" />
            </div>
            <div>
              <h3 className="font-semibold">Start AI Chat</h3>
              <p className="text-sm text-muted-foreground">Ask questions about your documents</p>
            </div>
          </CardContent>
        </Card>

        <Card className="cursor-pointer hover:shadow-md transition-shadow" onClick={() => router.push('/documents')}>
          <CardContent className="flex items-center p-6">
            <div className="p-2 bg-green-100 rounded-lg mr-4">
              <Upload className="h-6 w-6 text-green-600" />
            </div>
            <div>
              <h3 className="font-semibold">Upload Document</h3>
              <p className="text-sm text-muted-foreground">Add new files to your library</p>
            </div>
          </CardContent>
        </Card>

        <Card className="cursor-pointer hover:shadow-md transition-shadow" onClick={() => router.push('/search')}>
          <CardContent className="flex items-center p-6">
            <div className="p-2 bg-purple-100 rounded-lg mr-4">
              <Search className="h-6 w-6 text-purple-600" />
            </div>
            <div>
              <h3 className="font-semibold">Search Documents</h3>
              <p className="text-sm text-muted-foreground">Find information quickly</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Documents</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{isLoading ? '...' : stats.totalDocuments}</div>
            <p className="text-xs text-muted-foreground">
              {stats.recentUploads} uploaded this week
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Chat Sessions</CardTitle>
            <MessageSquare className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{isLoading ? '...' : stats.chatSessions}</div>
            <p className="text-xs text-muted-foreground">
              AI conversations
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Searches Today</CardTitle>
            <Search className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{isLoading ? '...' : stats.searchesToday}</div>
            <p className="text-xs text-muted-foreground">
              Document queries
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Recent Uploads</CardTitle>
            <Upload className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{isLoading ? '...' : stats.recentUploads}</div>
            <p className="text-xs text-muted-foreground">
              This week
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Recent Activity */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Activity</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="text-center py-4 text-muted-foreground">
              Loading recent activity...
            </div>
          ) : recentActivity.length === 0 ? (
            <div className="text-center py-4 text-muted-foreground">
              No recent activity
            </div>
          ) : (
            <div className="space-y-4">
              {recentActivity.map((activity) => (
                <div key={activity.id} className="flex items-center space-x-4">
                  <div className="p-2 bg-muted rounded-lg">
                    {getActivityIcon(activity.type)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium truncate">{activity.title}</p>
                    <p className="text-sm text-muted-foreground">{activity.description}</p>
                  </div>
                  <div className="text-sm text-muted-foreground">
                    {formatTimeAgo(activity.timestamp)}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}