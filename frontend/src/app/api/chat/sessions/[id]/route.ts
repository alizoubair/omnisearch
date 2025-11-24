import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'

const backendUrl = process.env.BACKEND_API_URL || process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8000'

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions)
    
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const accessToken = (session as any).accessToken || session.user.id

    const response = await fetch(`${backendUrl}/api/v1/chat/sessions/${params.id}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      signal: AbortSignal.timeout(30000), // 30 second timeout
    })

    if (!response.ok) {
      if (response.status === 404) {
        return NextResponse.json({ error: 'Chat session not found' }, { status: 404 })
      }
      const errorText = await response.text().catch(() => '')
      console.error(`Backend get session error: ${response.status} - ${errorText}`)
      return NextResponse.json(
        { error: errorText || 'Failed to fetch chat session' },
        { status: response.status }
      )
    }

    const data = await response.json()
    return NextResponse.json(data)

  } catch (error: any) {
    console.error('Chat session GET API error:', error)
    
    // Handle timeout
    if (error.name === 'TimeoutError' || error.name === 'AbortError') {
      return NextResponse.json(
        { error: 'Request timeout - the server took too long to respond' },
        { status: 408 }
      )
    }
    
    return NextResponse.json(
      { error: 'Failed to fetch chat session' },
      { status: 500 }
    )
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions)
    
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const accessToken = (session as any).accessToken || session.user.id

    const response = await fetch(`${backendUrl}/api/v1/chat/sessions/${params.id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
      signal: AbortSignal.timeout(30000), // 30 second timeout
    })

    if (!response.ok) {
      if (response.status === 404) {
        return NextResponse.json({ error: 'Chat session not found' }, { status: 404 })
      }
      const errorText = await response.text().catch(() => '')
      console.error(`Backend delete session error: ${response.status} - ${errorText}`)
      return NextResponse.json(
        { error: errorText || 'Failed to delete chat session' },
        { status: response.status }
      )
    }

    return NextResponse.json({ success: true })

  } catch (error: any) {
    console.error('Chat session DELETE API error:', error)
    
    // Handle timeout
    if (error.name === 'TimeoutError' || error.name === 'AbortError') {
      return NextResponse.json(
        { error: 'Request timeout - the server took too long to respond' },
        { status: 408 }
      )
    }
    
    return NextResponse.json(
      { error: 'Failed to delete chat session' },
      { status: 500 }
    )
  }
}

