import { useState, useEffect, useCallback } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import {
  ActiveFilters,
  SidebarConfig
} from './types';

// Default configuration
const defaultConfig: SidebarConfig = {
  defaultCollapsed: false,
  persistState: true,
  showRecentSearches: true,
  maxRecentSearches: 5,
  showCollections: true,
  showFilters: true,
  theme: 'dark'
};

export const useSidebar = (config: Partial<SidebarConfig> = {}) => {
  const router = useRouter();
  const pathname = usePathname();
  const finalConfig = { ...defaultConfig, ...config };

  // State management
  const [isCollapsed, setIsCollapsed] = useState<boolean>(() => {
    if (!finalConfig.persistState) return finalConfig.defaultCollapsed;
    // Check if we're in the browser before accessing localStorage
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('omnisearch_sidebar_collapsed');
      return saved ? JSON.parse(saved) : finalConfig.defaultCollapsed;
    }
    return finalConfig.defaultCollapsed;
  });

  const [activeFilters, setActiveFilters] = useState<ActiveFilters>({});
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Toggle sidebar collapse
  const toggleSidebar = useCallback(() => {
    const newCollapsed = !isCollapsed;
    setIsCollapsed(newCollapsed);

    if (finalConfig.persistState && typeof window !== 'undefined') {
      localStorage.setItem('omnisearch_sidebar_collapsed', JSON.stringify(newCollapsed));
    }
  }, [isCollapsed, finalConfig.persistState]);

  // Navigation handlers using Next.js router
  const handleNavigation = useCallback((path: string) => {
    router.push(path);
  }, [router]);

  // Check if path is active
  const isActivePath = useCallback((path: string): boolean => {
    return pathname === path;
  }, [pathname]);

  // Filter management (simplified without URL sync)
  const updateFilter = useCallback((filterType: keyof ActiveFilters, value: string | string[]) => {
    const newFilters = {
      ...activeFilters,
      [filterType]: value
    };

    setActiveFilters(newFilters);

    // In a real app, you might want to sync this with a global state or API
    console.log('Filter updated:', filterType, value);
  }, [activeFilters]);

  const clearFilters = useCallback(() => {
    setActiveFilters({});
  }, []);

  // Initialize data
  useEffect(() => {
    setLoading(false);
    setError(null);
  }, []);

  return {
    // State
    isCollapsed,
    activeFilters,
    loading,
    error,

    // Actions
    toggleSidebar,
    updateFilter,
    clearFilters,

    // Navigation
    handleNavigation,
    isActivePath,

    // Configuration
    config: finalConfig
  };
};