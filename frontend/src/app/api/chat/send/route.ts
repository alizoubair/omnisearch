import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'

const backendUrl = process.env.BACKEND_API_URL || process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8000'

export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions)
    
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()
    const { message, sessionId, documentIds } = body

    if (!message || !sessionId) {
      return NextResponse.json({ error: 'Message and sessionId are required' }, { status: 400 })
    }

    const accessToken = (session as any).accessToken || session.user.id

    console.log('Chat send request:', { message, sessionId, documentIds, documentIdsType: typeof documentIds, documentIdsLength: documentIds?.length })

    const requestBody: any = { message, session_id: sessionId }
    if (documentIds && Array.isArray(documentIds) && documentIds.length > 0) {
      // Ensure document IDs are in the correct format (UUIDs as strings)
      requestBody.document_ids = documentIds.filter((id: string) => {
        // Filter out invalid IDs
        return id && typeof id === 'string' && id.length > 0
      })
      console.log('Sending with document IDs:', requestBody.document_ids)
    } else {
      console.log('No document IDs provided or empty array')
    }

    const response = await fetch(`${backendUrl}/api/v1/chat/`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody),
      signal: AbortSignal.timeout(60000), // 60 second timeout for AI responses
    })

    if (!response.ok) {
      const errorText = await response.text().catch(() => '')
      console.error(`Backend chat error: ${response.status} - ${errorText}`)
      return NextResponse.json(
        { error: errorText || 'Failed to send chat message' },
        { status: response.status }
      )
    }

    const data = await response.json()
    return NextResponse.json(data)

  } catch (error: any) {
    console.error('Chat send API error:', error)
    
    // Handle timeout
    if (error.name === 'TimeoutError' || error.name === 'AbortError') {
      return NextResponse.json(
        { error: 'Request timeout - the server took too long to respond' },
        { status: 408 }
      )
    }
    
    return NextResponse.json(
      { error: 'Failed to process chat message' },
      { status: 500 }
    )
  }
}