'use client'

import { useCallback, useState } from 'react'
import { useDropzone } from 'react-dropzone'
import { Upload, File, X, CheckCircle, AlertCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { useDocumentStore } from '@/store/useDocumentStore'
import { useToast } from '@/hooks/use-toast'
import { formatFileSize, isValidFileType, generateId } from '@/lib/utils'
import { UploadProgress } from '@/types'

interface FileUploadProps {
  onUploadComplete?: (files: File[]) => void
  maxFiles?: number
  maxSize?: number
}

export function FileUpload({ 
  onUploadComplete, 
  maxFiles = 10, 
  maxSize = 10 * 1024 * 1024 // 10MB 
}: FileUploadProps) {
  const [isDragging, setIsDragging] = useState(false)
  const { uploads, addUpload, updateUpload, removeUpload } = useDocumentStore()
  const { toast } = useToast()

  const onDrop = useCallback((acceptedFiles: File[], rejectedFiles: any[]) => {
    setIsDragging(false)

    // Handle rejected files
    rejectedFiles.forEach(({ file, errors }) => {
      errors.forEach((error: any) => {
        toast({
          title: "Upload Error",
          description: `${file.name}: ${error.message}`,
          variant: "destructive"
        })
      })
    })

    // Process accepted files
    acceptedFiles.forEach((file) => {
      const fileId = generateId()
      
      // Add to upload queue
      addUpload({
        fileId,
        fileName: file.name,
        progress: 0,
        status: 'uploading'
      })

      // Upload file to backend
      uploadFile(fileId, file)
    })

    if (onUploadComplete && acceptedFiles.length > 0) {
      onUploadComplete(acceptedFiles)
    }
  }, [addUpload, toast, onUploadComplete])

  const uploadFile = async (fileId: string, file: File) => {
    try {
      const formData = new FormData()
      formData.append('file', file)
      formData.append('name', file.name)

      // Start upload
      updateUpload(fileId, { progress: 10, status: 'uploading' })

      const response = await fetch('/api/documents', {
        method: 'POST',
        body: formData,
      })

      updateUpload(fileId, { progress: 50 })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.error || 'Upload failed')
      }

      const result = await response.json()
      
      // Update progress to processing
      updateUpload(fileId, { 
        progress: 80, 
        status: 'processing' 
      })

      // Wait a bit for processing
      await new Promise(resolve => setTimeout(resolve, 1000))

      // Complete upload
      updateUpload(fileId, { 
        status: 'completed',
        progress: 100
      })

      toast({
        title: "Upload Complete",
        description: `${file.name} has been uploaded successfully.`
      })

      // Remove from upload queue after 3 seconds
      setTimeout(() => {
        removeUpload(fileId)
      }, 3000)

    } catch (error) {
      updateUpload(fileId, { 
        status: 'error',
        error: error instanceof Error ? error.message : 'Upload failed. Please try again.'
      })
      
      toast({
        title: "Upload Failed",
        description: `Failed to upload ${file.name}: ${error instanceof Error ? error.message : 'Unknown error'}`,
        variant: "destructive"
      })
    }
  }

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    onDragEnter: () => setIsDragging(true),
    onDragLeave: () => setIsDragging(false),
    accept: {
      'application/pdf': ['.pdf'],
      'application/msword': ['.doc'],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx'],
      'text/plain': ['.txt'],
      'image/*': ['.png', '.jpg', '.jpeg', '.gif']
    },
    maxFiles,
    maxSize,
    validator: (file) => {
      if (!isValidFileType(file)) {
        return {
          code: 'file-invalid-type',
          message: 'File type not supported'
        }
      }
      return null
    }
  })

  const removeFromQueue = (fileId: string) => {
    removeUpload(fileId)
  }

  return (
    <div className="space-y-4">
      {/* Upload Area */}
      <Card className={`transition-all duration-200 ${
        isDragActive || isDragging 
          ? 'border-primary bg-primary/5 scale-105' 
          : 'border-dashed border-muted-foreground/25 hover:border-muted-foreground/50'
      }`}>
        <CardContent className="p-8">
          <div
            {...getRootProps()}
            className="flex flex-col items-center justify-center text-center cursor-pointer"
          >
            <input {...getInputProps()} />
            <Upload className={`h-12 w-12 mb-4 ${
              isDragActive ? 'text-primary' : 'text-muted-foreground'
            }`} />
            <h3 className="text-lg font-semibold mb-2">
              {isDragActive ? 'Drop files here' : 'Upload Documents'}
            </h3>
            <p className="text-muted-foreground mb-4">
              Drag and drop files here, or click to browse
            </p>
            <div className="text-sm text-muted-foreground space-y-1">
              <p>Supported formats: PDF, DOC, DOCX, TXT, Images</p>
              <p>Maximum file size: {formatFileSize(maxSize)}</p>
              <p>Maximum files: {maxFiles}</p>
            </div>
            <Button variant="outline" className="mt-4">
              Browse Files
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Upload Progress */}
      {uploads.length > 0 && (
        <Card>
          <CardContent className="p-4">
            <h4 className="font-semibold mb-3">Upload Progress</h4>
            <div className="space-y-3">
              {uploads.map((upload) => (
                <UploadItem
                  key={upload.fileId}
                  upload={upload}
                  onRemove={() => removeFromQueue(upload.fileId)}
                />
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

interface UploadItemProps {
  upload: UploadProgress
  onRemove: () => void
}

function UploadItem({ upload, onRemove }: UploadItemProps) {
  const getStatusIcon = () => {
    switch (upload.status) {
      case 'completed':
        return <CheckCircle className="h-4 w-4 text-green-500" />
      case 'error':
        return <AlertCircle className="h-4 w-4 text-red-500" />
      default:
        return <File className="h-4 w-4 text-blue-500" />
    }
  }

  const getStatusText = () => {
    switch (upload.status) {
      case 'uploading':
        return `Uploading... ${upload.progress}%`
      case 'processing':
        return 'Processing document...'
      case 'completed':
        return 'Upload complete'
      case 'error':
        return upload.error || 'Upload failed'
      default:
        return 'Preparing...'
    }
  }

  return (
    <div className="flex items-center space-x-3 p-3 bg-muted/50 rounded-lg">
      {getStatusIcon()}
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium truncate">{upload.fileName}</p>
        <p className="text-xs text-muted-foreground">{getStatusText()}</p>
        {upload.status === 'uploading' && (
          <div className="w-full bg-gray-200 rounded-full h-1.5 mt-1">
            <div
              className="bg-blue-600 h-1.5 rounded-full transition-all duration-300"
              style={{ width: `${upload.progress}%` }}
            />
          </div>
        )}
      </div>
      <Button
        variant="ghost"
        size="sm"
        onClick={onRemove}
        className="h-8 w-8 p-0"
      >
        <X className="h-4 w-4" />
      </Button>
    </div>
  )
}