import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { mockSessions } from '@/lib/mock-db'

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions)
    
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const userEmail = session.user?.email || ''
    const userSessions = mockSessions.get(userEmail) || []
    const chatSession = userSessions.find((s: any) => s.id === params.id)

    if (!chatSession) {
      return NextResponse.json({ error: 'Session not found' }, { status: 404 })
    }

    return NextResponse.json({
      success: true,
      data: chatSession
    })

  } catch (error) {
    console.error('Get session error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch chat session' },
      { status: 500 }
    )
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions)
    
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { message } = await request.json()
    const userEmail = session.user?.email || ''
    const userSessions = mockSessions.get(userEmail) || []
    const sessionIndex = userSessions.findIndex((s: any) => s.id === params.id)

    if (sessionIndex === -1) {
      return NextResponse.json({ error: 'Session not found' }, { status: 404 })
    }

    // Add message to session
    userSessions[sessionIndex].messages.push(message)
    userSessions[sessionIndex].updatedAt = new Date().toISOString()
    
    // Update title if it's the first user message
    if (userSessions[sessionIndex].messages.length === 1 && message.role === 'user') {
      userSessions[sessionIndex].title = message.content.substring(0, 50) + '...'
    }

    mockSessions.set(userEmail, userSessions)

    return NextResponse.json({
      success: true,
      data: userSessions[sessionIndex]
    })

  } catch (error) {
    console.error('Update session error:', error)
    return NextResponse.json(
      { error: 'Failed to update chat session' },
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
    
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const userEmail = session.user?.email || ''
    const userSessions = mockSessions.get(userEmail) || []
    const filteredSessions = userSessions.filter((s: any) => s.id !== params.id)

    if (filteredSessions.length === userSessions.length) {
      return NextResponse.json({ error: 'Session not found' }, { status: 404 })
    }

    mockSessions.set(userEmail, filteredSessions)

    return NextResponse.json({
      success: true,
      message: 'Session deleted successfully'
    })

  } catch (error) {
    console.error('Delete session error:', error)
    return NextResponse.json(
      { error: 'Failed to delete chat session' },
      { status: 500 }
    )
  }
}