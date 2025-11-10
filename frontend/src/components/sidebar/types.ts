// Omnisearch Sidebar Types

export interface NavigationItem {
  id: string;
  icon: string;
  label: string;
  path: string;
  badge?: number;
  disabled?: boolean;
}

export interface RecentSearch {
  query: string;
  timestamp: string;
  results: number;
  id?: string;
}

export interface Collection {
  id: number;
  name: string;
  count: number;
  icon: string;
  description?: string;
  color?: string;
  isPrivate?: boolean;
}

export interface ActiveFilters {
  fileType?: string;
  dateRange?: string;
  author?: string;
  tags?: string[];
  language?: string;
  size?: string;
}

export interface SidebarProps {
  isCollapsed?: boolean;
  onToggle?: () => void;
  className?: string;
}

export interface UserInfo {
  name: string;
  role: string;
  avatar?: string;
  email?: string;
}

export interface SidebarSection {
  id: string;
  title: string;
  icon: string;
  visible: boolean;
  collapsible?: boolean;
  collapsed?: boolean;
}

// Filter options
export interface FilterOption {
  value: string;
  label: string;
  count?: number;
}

export interface FilterGroup {
  id: string;
  label: string;
  type: 'select' | 'multiselect' | 'range' | 'checkbox';
  options: FilterOption[];
}

// Search context
export interface SearchContext {
  query: string;
  filters: ActiveFilters;
  results: number;
  timestamp: string;
}

// Sidebar configuration
export interface SidebarConfig {
  defaultCollapsed: boolean;
  persistState: boolean;
  showRecentSearches: boolean;
  maxRecentSearches: number;
  showCollections: boolean;
  showFilters: boolean;
  theme: 'light' | 'dark' | 'auto';
}

// Event handlers
export interface SidebarEventHandlers {
  onNavigate?: (path: string) => void;
  onSearch?: (query: string) => void;
  onFilterChange?: (filters: ActiveFilters) => void;
  onCollectionSelect?: (collectionId: number) => void;
  onRecentSearchSelect?: (search: RecentSearch) => void;
}

// API response types
export interface CollectionsResponse {
  collections: Collection[];
  total: number;
}

export interface RecentSearchesResponse {
  searches: RecentSearch[];
  total: number;
}

export interface FilterOptionsResponse {
  fileTypes: FilterOption[];
  authors: FilterOption[];
  tags: FilterOption[];
  languages: FilterOption[];
}