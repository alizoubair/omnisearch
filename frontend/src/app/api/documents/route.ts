import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'

// Use BACKEND_API_URL for server-side calls in Docker Compose (http://backend:8000)
// In Azure, BACKEND_API_URL is not set, so it falls back to NEXT_PUBLIC_API_BASE_URL (Internal Load Balancer IP)
// Fallback to localhost for local development outside Docker
const BACKEND_URL = process.env.BACKEND_API_URL || process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8000'

export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions)
    
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { searchParams } = new URL(request.url)
    const limit = searchParams.get('limit') || '50'
    const offset = searchParams.get('offset') || '0'
    const status = searchParams.get('status')

    const params = new URLSearchParams({
      limit,
      offset,
      ...(status && { status_filter: status })
    })

    const accessToken = (session as any).accessToken || session.user.id
    
    const response = await fetch(`${BACKEND_URL}/api/v1/documents?${params}`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      // Add timeout
      signal: AbortSignal.timeout(30000), // 30 second timeout
    })

    if (!response.ok) {
      console.error(`Backend responded with ${response.status}`)
      // Return empty array instead of throwing to prevent frontend from hanging
      return NextResponse.json([])
    }

    const documents = await response.json()
    
    // Ensure we always return an array
    if (!Array.isArray(documents)) {
      console.error('Backend did not return an array:', documents)
      return NextResponse.json([])
    }
    
    return NextResponse.json(documents)
  } catch (error: any) {
    console.error('Error fetching documents:', error)
    
    // Handle timeout - return empty array instead of error
    if (error.name === 'TimeoutError' || error.name === 'AbortError') {
      console.error('Request timeout - returning empty array')
      return NextResponse.json([])
    }
    
    // Return empty array on any error to prevent frontend from hanging
    return NextResponse.json([])
  }
}

export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions)
    
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const formData = await request.formData()
    
    const accessToken = (session as any).accessToken || session.user.id
    
    const response = await fetch(`${BACKEND_URL}/api/v1/documents/upload`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
      body: formData,
    })

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}))
      throw new Error(errorData.detail || `Backend responded with ${response.status}`)
    }

    const result = await response.json()
    return NextResponse.json(result)
  } catch (error) {
    console.error('Error uploading document:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to upload document' },
      { status: 500 }
    )
  }
}