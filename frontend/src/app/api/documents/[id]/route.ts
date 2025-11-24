import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'

// Use BACKEND_API_URL for server-side calls in Docker Compose (http://backend:8000)
// In Azure, BACKEND_API_URL is not set, so it falls back to NEXT_PUBLIC_API_BASE_URL (Internal Load Balancer IP)
// Fallback to localhost for local development outside Docker
const BACKEND_URL = process.env.BACKEND_API_URL || process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8000'

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
    
    const response = await fetch(`${BACKEND_URL}/api/v1/documents/${params.id}`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      if (response.status === 404) {
        return NextResponse.json({ error: 'Document not found' }, { status: 404 })
      }
      throw new Error(`Backend responded with ${response.status}`)
    }

    const document = await response.json()
    return NextResponse.json(document)
  } catch (error) {
    console.error('Error fetching document:', error)
    return NextResponse.json(
      { error: 'Failed to fetch document' },
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
    
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()

    const accessToken = (session as any).accessToken || session.user.id
    
    const response = await fetch(`${BACKEND_URL}/api/v1/documents/${params.id}`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    })

    if (!response.ok) {
      if (response.status === 404) {
        return NextResponse.json({ error: 'Document not found' }, { status: 404 })
      }
      throw new Error(`Backend responded with ${response.status}`)
    }

    const document = await response.json()
    return NextResponse.json(document)
  } catch (error) {
    console.error('Error updating document:', error)
    return NextResponse.json(
      { error: 'Failed to update document' },
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
    
    const response = await fetch(`${BACKEND_URL}/api/v1/documents/${params.id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
      signal: AbortSignal.timeout(30000), // 30 second timeout
    })

    if (!response.ok) {
      if (response.status === 404) {
        return NextResponse.json({ error: 'Document not found' }, { status: 404 })
      }
      const errorText = await response.text().catch(() => '')
      console.error(`Backend delete error: ${response.status} - ${errorText}`)
      return NextResponse.json(
        { error: `Failed to delete document: ${response.statusText}` },
        { status: response.status }
      )
    }

    return NextResponse.json({ success: true })
  } catch (error: any) {
    console.error('Error deleting document:', error)
    
    // Handle timeout
    if (error.name === 'TimeoutError' || error.name === 'AbortError') {
      return NextResponse.json(
        { error: 'Request timeout - the server took too long to respond' },
        { status: 408 }
      )
    }
    
    return NextResponse.json(
      { error: 'Failed to delete document' },
      { status: 500 }
    )
  }
}