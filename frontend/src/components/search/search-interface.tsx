'use client'

import { useState, useEffect } from 'react'
import { Search, Filter, Clock, FileText, Zap } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useToast } from '@/hooks/use-toast'
import { debounce, formatDate } from '@/lib/utils'
import { SearchResult, SearchFilters } from '@/types'
import { searchApi } from '@/lib/api'
import type { ChangeEvent } from 'react'

export function SearchInterface() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<SearchResult[]>([])
  const [isSearching, setIsSearching] = useState(false)
  const [searchHistory, setSearchHistory] = useState<string[]>([])
  const [filters, setFilters] = useState<SearchFilters>({})
  const [searchType, setSearchType] = useState<'semantic' | 'keyword'>('semantic')
  
  const { toast } = useToast()



  const debouncedSearch = debounce(async (searchQuery: string, searchType: 'semantic' | 'keyword', filters: SearchFilters) => {
    if (!searchQuery.trim()) {
      setResults([])
      return
    }

    setIsSearching(true)
    
    try {
      const response = searchType === 'semantic'
        ? await searchApi.searchDocuments(searchQuery, 20, 0, filters)
        : await searchApi.searchDocumentsSimple(searchQuery, 20, 0)
      setResults(response)
      
      // Add to search history
      if (!searchHistory.includes(searchQuery)) {
        setSearchHistory(prev => [searchQuery, ...prev.slice(0, 4)])
      }
      
    } catch (error) {
      console.error('Search error:', error)
      toast({
        title: "Search Error",
        description: error instanceof Error ? error.message : "Failed to perform search. Please try again.",
        variant: "destructive"
      })
      setResults([])
    } finally {
      setIsSearching(false)
    }
  }, 500)

  useEffect(() => {
    debouncedSearch(query, searchType, filters)
  }, [query, searchType, filters, debouncedSearch])

  const handleSearchTypeChange = (type: 'semantic' | 'keyword') => {
    setSearchType(type)
    if (query) {
      debouncedSearch(query, type, filters)
    }
  }

  const handleHistoryClick = (historyQuery: string) => {
    setQuery(historyQuery)
  }

  return (
    <div className="space-y-6">
      {/* Search Header */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <Search className="h-5 w-5" />
            <span>Search Documents</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Search Input */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              value={query}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setQuery(e.target.value)}
              placeholder="Search your documents..."
              className="pl-10 pr-4 h-12 text-base"
            />
          </div>

          {/* Search Type Toggle */}
          <div className="flex items-center space-x-2">
            <span className="text-sm text-muted-foreground">Search type:</span>
            <Button
              variant={searchType === 'semantic' ? 'default' : 'outline'}
              size="sm"
              onClick={() => handleSearchTypeChange('semantic')}
              className="flex items-center space-x-1"
            >
              <Zap className="h-3 w-3" />
              <span>Semantic</span>
            </Button>
            <Button
              variant={searchType === 'keyword' ? 'default' : 'outline'}
              size="sm"
              onClick={() => handleSearchTypeChange('keyword')}
              className="flex items-center space-x-1"
            >
              <FileText className="h-3 w-3" />
              <span>Keyword</span>
            </Button>
          </div>

          {/* Search History */}
          {searchHistory.length > 0 && !query && (
            <div>
              <h4 className="text-sm font-medium mb-2 flex items-center space-x-1">
                <Clock className="h-4 w-4" />
                <span>Recent Searches</span>
              </h4>
              <div className="flex flex-wrap gap-2">
                {searchHistory.map((historyItem, index) => (
                  <Button
                    key={index}
                    variant="outline"
                    size="sm"
                    onClick={() => handleHistoryClick(historyItem)}
                    className="text-xs"
                  >
                    {historyItem}
                  </Button>
                ))}
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Search Results */}
      {query && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              <span>
                {isSearching ? 'Searching...' : `${results.length} results for "${query}"`}
              </span>
              {searchType === 'semantic' && (
                <span className="text-sm text-muted-foreground flex items-center space-x-1">
                  <Zap className="h-3 w-3" />
                  <span>AI-powered search</span>
                </span>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            {isSearching ? (
              <div className="p-8 text-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
                <p className="text-muted-foreground">Searching your documents...</p>
              </div>
            ) : results.length === 0 ? (
              <div className="p-8 text-center">
                <Search className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                <h3 className="text-lg font-semibold mb-2">No results found</h3>
                <p className="text-muted-foreground">
                  Try different keywords or check your spelling
                </p>
              </div>
            ) : (
              <div className="divide-y">
                {results.map((result) => (
                  <SearchResultItem key={result.id} result={result} />
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  )
}

interface SearchResultItemProps {
  result: SearchResult
}

function SearchResultItem({ result }: SearchResultItemProps) {
  const handleResultClick = () => {
    // Handle result click - could open document or show more details
    console.log('Clicked result:', result)
  }

  const highlightText = (text: string, highlights: string[]) => {
    if (!highlights || highlights.length === 0) return text

    let highlightedText = text
    highlights.forEach(highlight => {
      const regex = new RegExp(`(${highlight})`, 'gi')
      highlightedText = highlightedText.replace(
        regex,
        '<mark class="bg-yellow-200 dark:bg-yellow-800 px-1 rounded">$1</mark>'
      )
    })

    return highlightedText
  }

  return (
    <div 
      className="p-6 hover:bg-muted/50 cursor-pointer transition-colors"
      onClick={handleResultClick}
    >
      <div className="space-y-3">
        {/* Result Header */}
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <h3 className="font-semibold text-lg mb-1">{result.title}</h3>
            <div className="flex items-center space-x-2 text-sm text-muted-foreground">
              <FileText className="h-4 w-4" />
              <span>{result.documentName}</span>
              {result.metadata?.page && (
                <>
                  <span>•</span>
                  <span>Page {result.metadata.page}</span>
                </>
              )}
              {result.metadata?.section && (
                <>
                  <span>•</span>
                  <span>{result.metadata.section}</span>
                </>
              )}
            </div>
          </div>
          <div className="text-right">
            <div className="text-sm font-medium text-primary">
              {Math.round(result.score * 100)}% match
            </div>
          </div>
        </div>

        {/* Content Preview */}
        <div 
          className="text-sm text-muted-foreground leading-relaxed"
          dangerouslySetInnerHTML={{
            __html: highlightText(result.content, result.highlights || [])
          }}
        />

        {/* Highlights */}
        {result.highlights && result.highlights.length > 0 && (
          <div className="flex flex-wrap gap-1">
            {result.highlights.map((highlight, index) => (
              <span
                key={index}
                className="px-2 py-1 text-xs bg-primary/10 text-primary rounded-full"
              >
                {highlight}
              </span>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}