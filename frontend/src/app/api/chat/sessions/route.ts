import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'

const backendUrl = process.env.BACKEND_API_URL || process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8000'

export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions)
    
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const accessToken = (session as any).accessToken || session.user.id

    const response = await fetch(`${backendUrl}/api/v1/chat/sessions`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      // Add timeout
      signal: AbortSignal.timeout(30000), // 30 second timeout
    })

    if (!response.ok) {
      const error = await response.text()
      console.error('Backend error:', response.status, error)
      return NextResponse.json(
        { error: error || 'Failed to fetch chat sessions' },
        { status: response.status }
      )
    }

    const data = await response.json()
    return NextResponse.json(data)

  } catch (error: any) {
    console.error('Chat sessions API error:', error)
    
    // Handle timeout
    if (error.name === 'TimeoutError' || error.name === 'AbortError') {
      return NextResponse.json(
        { error: 'Request timeout - the server took too long to respond' },
        { status: 408 }
      )
    }
    
    return NextResponse.json(
      { error: 'Failed to fetch chat sessions' },
      { status: 500 }
    )
  }
}

