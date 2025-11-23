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
    
    const response = await fetch(`${BACKEND_URL}/api/v1/documents/${params.id}/content`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      if (response.status === 404) {
        return NextResponse.json({ error: 'Document content not found' }, { status: 404 })
      }
      throw new Error(`Backend responded with ${response.status}`)
    }

    const data = await response.json()
    return NextResponse.json(data)
  } catch (error) {
    console.error('Error fetching document content:', error)
    return NextResponse.json(
      { error: 'Failed to fetch document content' },
      { status: 500 }
    )
  }
}
