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
    
    const response = await fetch(`${BACKEND_URL}/api/v1/documents/${params.id}/download`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    })

    if (!response.ok) {
      if (response.status === 404) {
        return NextResponse.json({ error: 'Document not found' }, { status: 404 })
      }
      throw new Error(`Backend responded with ${response.status}`)
    }

    const blob = await response.blob()
    const contentType = response.headers.get('content-type') || 'application/octet-stream'
    const contentDisposition = response.headers.get('content-disposition') || ''

    return new NextResponse(blob, {
      headers: {
        'Content-Type': contentType,
        'Content-Disposition': contentDisposition,
      },
    })
  } catch (error) {
    console.error('Error downloading document:', error)
    return NextResponse.json(
      { error: 'Failed to download document' },
      { status: 500 }
    )
  }
}
