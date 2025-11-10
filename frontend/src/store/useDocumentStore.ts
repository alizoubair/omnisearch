import { create } from 'zustand'
import { Document, UploadProgress } from '@/types'

interface DocumentStore {
  documents: Document[]
  uploads: UploadProgress[]
  selectedDocument: Document | null
  
  // Actions
  setDocuments: (documents: Document[]) => void
  addDocument: (document: Document) => void
  updateDocument: (id: string, updates: Partial<Document>) => void
  removeDocument: (id: string) => void
  setSelectedDocument: (document: Document | null) => void
  
  // Upload actions
  addUpload: (upload: UploadProgress) => void
  updateUpload: (fileId: string, updates: Partial<UploadProgress>) => void
  removeUpload: (fileId: string) => void
  clearUploads: () => void
}

export const useDocumentStore = create<DocumentStore>((set, get) => ({
  documents: [],
  uploads: [],
  selectedDocument: null,
  
  setDocuments: (documents) => set({ documents }),
  
  addDocument: (document) => set((state) => ({
    documents: [document, ...state.documents]
  })),
  
  updateDocument: (id, updates) => set((state) => ({
    documents: state.documents.map(doc => 
      doc.id === id ? { ...doc, ...updates } : doc
    )
  })),
  
  removeDocument: (id) => set((state) => ({
    documents: state.documents.filter(doc => doc.id !== id),
    selectedDocument: state.selectedDocument?.id === id ? null : state.selectedDocument
  })),
  
  setSelectedDocument: (document) => set({ selectedDocument: document }),
  
  addUpload: (upload) => set((state) => ({
    uploads: [...state.uploads, upload]
  })),
  
  updateUpload: (fileId, updates) => set((state) => ({
    uploads: state.uploads.map(upload =>
      upload.fileId === fileId ? { ...upload, ...updates } : upload
    )
  })),
  
  removeUpload: (fileId) => set((state) => ({
    uploads: state.uploads.filter(upload => upload.fileId !== fileId)
  })),
  
  clearUploads: () => set({ uploads: [] })
}))