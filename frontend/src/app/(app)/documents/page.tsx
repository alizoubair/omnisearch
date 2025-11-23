'use client'

import { useState } from 'react'
import { DocumentLibrary } from '@/components/documents/document-library'
import { DocumentUpload } from '@/components/documents/document-upload'
import { Upload, FileText } from 'lucide-react'

export default function DocumentsPage() {
    const [showUpload, setShowUpload] = useState(false)
    const [refreshTrigger, setRefreshTrigger] = useState(0)

    const handleUploadComplete = () => {
        setShowUpload(false)
        // Trigger refresh of document library
        setRefreshTrigger(prev => prev + 1)
    }

    return (
        <div className="h-full flex flex-col">
            {/* Page Header */}
            <div className="flex items-center justify-between mb-6">
                <div>
                    <h1 className="text-2xl font-semibold text-foreground">Documents</h1>
                    <p className="text-muted-foreground">Manage and search your document library</p>
                </div>

                <button
                    onClick={() => setShowUpload(true)}
                    className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors"
                >
                    <Upload size={16} />
                    Upload Documents
                </button>
            </div>

            {/* Upload Modal */}
            {showUpload && (
                <DocumentUpload
                    onClose={() => setShowUpload(false)}
                    onUploadComplete={handleUploadComplete}
                />
            )}

            {/* Document Library */}
            <div className="flex-1">
                <DocumentLibrary refreshTrigger={refreshTrigger} />
            </div>
        </div>
    )
}