'use client'

import { useState, useEffect } from 'react'
import { Search, Filter, MoreVertical, Download, Trash2, Eye, Tag } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useDocumentStore } from '@/store/useDocumentStore'
import { useToast } from '@/hooks/use-toast'
import { formatFileSize, formatDate, getFileIcon, debounce } from '@/lib/utils'
import { Document } from '@/types'
import { DocumentViewer } from './document-viewer'

export function DocumentLibrary() {
  const [searchQuery, setSearchQuery] = useState('')
  const [filteredDocuments, setFilteredDocuments] = useState<Document[]>([])
  const [selectedFilter, setSelectedFilter] = useState<'all' | 'ready' | 'processing' | 'error'>('all')
  const [viewingDocument, setViewingDocument] = useState<Document | null>(null)

  const { documents, setSelectedDocument, removeDocument } = useDocumentStore()
  const { toast } = useToast()

  // Fetch documents from backend
  useEffect(() => {
    const fetchDocuments = async () => {
      try {
        const response = await fetch('/api/documents')
        if (response.ok) {
          const backendDocuments = await response.json()

          // Transform backend format to frontend format
          const transformedDocuments: Document[] = backendDocuments.map((doc: any) => ({
            id: doc.id,
            name: doc.name,
            type: doc.file_type,
            size: doc.file_size,
            uploadedAt: doc.created_at,
            status: doc.status,
            metadata: doc.metadata
          }))

          useDocumentStore.getState().setDocuments(transformedDocuments)
        } else {
          console.error('Failed to fetch documents:', response.statusText)
        }
      } catch (error) {
        console.error('Error fetching documents:', error)
        toast({
          title: "Error",
          description: "Failed to load documents",
          variant: "destructive"
        })
      }
    }

    fetchDocuments()
  }, [])

  // Filter and search documents
  useEffect(() => {
    let filtered = documents

    // Apply status filter
    if (selectedFilter !== 'all') {
      filtered = filtered.filter(doc => doc.status === selectedFilter)
    }

    // Apply search filter
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase()
      filtered = filtered.filter(doc =>
        doc.name.toLowerCase().includes(query) ||
        doc.metadata?.tags?.some(tag => tag.toLowerCase().includes(query))
      )
    }

    setFilteredDocuments(filtered)
  }, [documents, searchQuery, selectedFilter])

  const debouncedSearch = debounce((query: string) => {
    setSearchQuery(query)
  }, 300)

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    debouncedSearch(e.target.value)
  }

  const handleDocumentClick = (document: Document) => {
    setSelectedDocument(document)
    setViewingDocument(document)
  }

  const handleDeleteDocument = async (document: Document) => {
    try {
      const response = await fetch(`/api/documents/${document.id}`, {
        method: 'DELETE'
      })

      if (response.ok) {
        removeDocument(document.id)
        toast({
          title: "Document Deleted",
          description: `${document.name} has been deleted`
        })
      } else {
        throw new Error('Failed to delete document')
      }
    } catch (error) {
      console.error('Error deleting document:', error)
      toast({
        title: "Error",
        description: "Failed to delete document",
        variant: "destructive"
      })
    }
  }



  return (
    <Card className="h-full">
      <CardHeader>
        <CardTitle>Document Library</CardTitle>

        {/* Search and Filter Bar */}
        <div className="flex space-x-4 mt-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search documents..."
              onChange={handleSearchChange}
              className="pl-10"
            />
          </div>

          <div className="flex space-x-2">
            {(['all', 'ready', 'processing', 'error'] as const).map((filter) => (
              <Button
                key={filter}
                variant={selectedFilter === filter ? 'default' : 'outline'}
                size="sm"
                onClick={() => setSelectedFilter(filter)}
              >
                {filter.charAt(0).toUpperCase() + filter.slice(1)}
              </Button>
            ))}
          </div>
        </div>
      </CardHeader>

      <CardContent className="p-0">
        {filteredDocuments.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">📄</div>
            <h3 className="text-lg font-semibold mb-2">No documents found</h3>
            <p className="text-muted-foreground">
              {searchQuery ? 'Try adjusting your search terms' : 'Upload some documents to get started'}
            </p>
          </div>
        ) : (
          <div className="divide-y">
            {filteredDocuments.map((document) => (
              <DocumentItem
                key={document.id}
                document={document}
                onClick={() => handleDocumentClick(document)}
                onDelete={() => handleDeleteDocument(document)}
                onView={() => setViewingDocument(document)}
              />
            ))}
          </div>
        )}
      </CardContent>

      {/* Document Viewer Modal */}
      {viewingDocument && (
        <DocumentViewer
          document={viewingDocument}
          onClose={() => setViewingDocument(null)}
        />
      )}
    </Card>
  )
}

// Helper function for status badges
const getStatusBadge = (status: Document['status']) => {
  const styles = {
    ready: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
    processing: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300',
    uploading: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
    error: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
  }

  return (
    <span className={`px-2 py-1 text-xs font-medium rounded-full ${styles[status]}`}>
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  )
}

interface DocumentItemProps {
  document: Document
  onClick: () => void
  onDelete: () => void
  onView: () => void
}

function DocumentItem({ document, onClick, onDelete, onView }: DocumentItemProps) {
  const [showActions, setShowActions] = useState(false)

  return (
    <div
      className="p-4 hover:bg-muted/50 cursor-pointer transition-colors"
      onClick={onClick}
    >
      <div className="flex items-center space-x-4">
        {/* Document Info */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center space-x-2 mb-1">
            <h4 className="font-medium truncate">{document.name}</h4>
            {getStatusBadge(document.status)}
          </div>

          <div className="flex items-center space-x-4 text-sm text-muted-foreground">
            <span>{formatFileSize(document.size)}</span>
            <span>{formatDate(document.uploadedAt)}</span>
            {document.metadata?.pages && (
              <span>{document.metadata.pages} pages</span>
            )}
          </div>

          {/* Tags */}
          {document.metadata?.tags && document.metadata.tags.length > 0 && (
            <div className="flex items-center space-x-1 mt-2">
              <Tag className="h-3 w-3 text-muted-foreground" />
              <div className="flex space-x-1">
                {document.metadata.tags.slice(0, 3).map((tag) => (
                  <span
                    key={tag}
                    className="px-2 py-1 text-xs bg-muted rounded-full"
                  >
                    {tag}
                  </span>
                ))}
                {document.metadata.tags.length > 3 && (
                  <span className="px-2 py-1 text-xs bg-muted rounded-full">
                    +{document.metadata.tags.length - 3}
                  </span>
                )}
              </div>
            </div>
          )}
        </div>

        {/* Actions */}
        <div className="relative">
          <Button
            variant="ghost"
            size="icon"
            onClick={(e) => {
              e.stopPropagation()
              setShowActions(!showActions)
            }}
          >
            <MoreVertical className="h-4 w-4" />
          </Button>

          {showActions && (
            <div className="absolute right-0 top-full mt-1 w-48 bg-background border rounded-md shadow-lg z-10">
              <div className="py-1">
                <button
                  className="flex items-center space-x-2 w-full px-3 py-2 text-sm hover:bg-muted"
                  onClick={(e) => {
                    e.stopPropagation()
                    setShowActions(false)
                    onView()
                  }}
                >
                  <Eye className="h-4 w-4" />
                  <span>View</span>
                </button>
                <button
                  className="flex items-center space-x-2 w-full px-3 py-2 text-sm hover:bg-muted"
                  onClick={(e) => {
                    e.stopPropagation()
                    setShowActions(false)
                    // Handle download action
                  }}
                >
                  <Download className="h-4 w-4" />
                  <span>Download</span>
                </button>
                <button
                  className="flex items-center space-x-2 w-full px-3 py-2 text-sm hover:bg-muted text-red-600"
                  onClick={(e) => {
                    e.stopPropagation()
                    setShowActions(false)
                    onDelete()
                  }}
                >
                  <Trash2 className="h-4 w-4" />
                  <span>Delete</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}