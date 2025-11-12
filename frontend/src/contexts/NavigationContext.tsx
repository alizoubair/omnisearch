'use client'

import React, { createContext, useContext, useState, ReactNode } from 'react';

// Define the available pages
export type PageType = 'home' | 'documents' | 'search' | 'chat';

interface NavigationContextType {
  currentPage: PageType;
  navigateTo: (page: PageType) => void;
  isActivePath: (path: string) => boolean;
}

const NavigationContext = createContext<NavigationContextType | undefined>(undefined);

interface NavigationProviderProps {
  children: ReactNode;
}

export const NavigationProvider: React.FC<NavigationProviderProps> = ({ children }) => {
  const [currentPage, setCurrentPage] = useState<PageType>('home');

  const navigateTo = (page: PageType) => {
    setCurrentPage(page);
  };

  const isActivePath = (path: string) => {
    // Convert path to page type (remove leading slash and convert to lowercase)
    const page = path.replace('/', '').toLowerCase() as PageType;
    return currentPage === page;
  };

  const value: NavigationContextType = {
    currentPage,
    navigateTo,
    isActivePath
  };

  return (
    <NavigationContext.Provider value={value}>
      {children}
    </NavigationContext.Provider>
  );
};

export const useNavigation = (): NavigationContextType => {
  const context = useContext(NavigationContext);
  if (context === undefined) {
    throw new Error('useNavigation must be used within a NavigationProvider');
  }
  return context;
};

// Helper hook for sidebar navigation
export const useNavigationHandlers = () => {
  const { navigateTo } = useNavigation();

  const handleNavigation = (path: string) => {
    const page = path.replace('/', '').toLowerCase() as PageType;
    navigateTo(page);
  };

  const handleRecentSearch = (query: string) => {
    // Navigate to search page and potentially set the query
    navigateTo('search');
    // In a real app, you'd also set the search query here
    console.log('Searching for:', query);
  };

  const handleCollectionClick = (collectionId: number) => {
    // Navigate to documents page and potentially filter by collection
    navigateTo('documents');
    console.log('Viewing collection:', collectionId);
  };

  return {
    handleNavigation,
    handleRecentSearch,
    handleCollectionClick
  };
};