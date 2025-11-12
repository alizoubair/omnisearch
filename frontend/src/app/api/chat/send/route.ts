import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'

export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions)
    
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { message, sessionId } = await request.json()

    if (!message || !sessionId) {
      return NextResponse.json({ error: 'Message and sessionId are required' }, { status: 400 })
    }

    // TODO: Replace with actual Azure OpenAI integration
    const aiResponse = await generateAIResponse(message, session.user?.email || '')

    return NextResponse.json({
      success: true,
      data: {
        id: `msg-${Date.now()}`,
        role: 'assistant',
        content: aiResponse.content,
        timestamp: new Date().toISOString(),
        sources: aiResponse.sources
      }
    })

  } catch (error) {
    console.error('Chat API error:', error)
    return NextResponse.json(
      { error: 'Failed to process chat message' },
      { status: 500 }
    )
  }
}

// Mock AI response function - replace with actual Azure OpenAI integration
async function generateAIResponse(message: string, userEmail: string) {
  // Simulate processing delay
  await new Promise(resolve => setTimeout(resolve, 1000))

  // Mock response based on message content
  const responses = {
    greeting: "Hello! I'm your AI assistant. I can help you find information in your documents, answer questions, and provide summaries. What would you like to know?",
    policy: "Based on your company documents, I found relevant policy information. According to the employee handbook, remote work is permitted with manager approval and requires adherence to communication guidelines.",
    benefits: "Your benefits package includes comprehensive health insurance, dental coverage, retirement plans with company matching, and professional development opportunities. All full-time employees are eligible after 90 days.",
    default: `I understand you're asking about "${message}". Let me search through your documents to find the most relevant information. Based on what I found, here's what I can tell you...`
  }

  let content = responses.default
  if (message.toLowerCase().includes('hello') || message.toLowerCase().includes('hi')) {
    content = responses.greeting
  } else if (message.toLowerCase().includes('policy') || message.toLowerCase().includes('remote')) {
    content = responses.policy
  } else if (message.toLowerCase().includes('benefit')) {
    content = responses.benefits
  }

  // Mock document sources
  const sources = [
    {
      documentId: 'doc-1',
      documentName: 'Employee Handbook.pdf',
      pageNumber: 12,
      relevanceScore: 0.92,
      snippet: 'Relevant excerpt from the document that supports the AI response...'
    },
    {
      documentId: 'doc-2',
      documentName: 'Company Policies.docx',
      pageNumber: 5,
      relevanceScore: 0.87,
      snippet: 'Additional context from another document that provides supporting information...'
    }
  ]

  return {
    content,
    sources: message.toLowerCase().includes('hello') ? [] : sources
  }
}