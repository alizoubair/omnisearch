'use client'

import React from 'react';
import { useSession } from 'next-auth/react';
import {
  Home,
  FileText,
  Search,
  MessageSquare,
  BarChart3,
  ChevronLeft,
  ChevronRight,
  Filter,
  User
} from 'lucide-react';
import { OmnisearchIcon } from '../ui/omnisearch-icon';
import { useSidebar } from './useSidebar';
import { NavigationItem, SidebarProps, ActiveFilters } from './types';
import './sidebar.css';



const Sidebar: React.FC<SidebarProps> = ({ isCollapsed: externalCollapsed, onToggle: externalToggle }) => {
  const { data: session } = useSession();
  
  // Use the custom hook for all sidebar functionality
  const {
    isCollapsed,
    activeFilters,
    loading,
    error,
    toggleSidebar,
    handleNavigation,
    updateFilter,
    isActivePath
  } = useSidebar();

  // Use external collapse state if provided, otherwise use internal state
  const sidebarCollapsed = externalCollapsed !== undefined ? externalCollapsed : isCollapsed;
  const handleToggle = externalToggle || toggleSidebar;

  // Navigation items with proper typing and icon components
  const navigationItems: NavigationItem[] = [
    { id: 'home', icon: 'Home', label: 'Home', path: '/' },
    { id: 'documents', icon: 'FileText', label: 'Documents', path: '/documents' },
    { id: 'search', icon: 'Search', label: 'Search', path: '/search' },
    { id: 'chat', icon: 'MessageSquare', label: 'AI Chat', path: '/chat' },
    { id: 'analytics', icon: 'BarChart3', label: 'Analytics', path: '/analytics' }
  ];

  // Icon component mapping
  const IconComponents = {
    Home,
    FileText,
    Search,
    MessageSquare,
    BarChart3,
    Filter,
    User
  };

  // Show loading state
  if (loading) {
    return (
      <div className={`sidebar ${sidebarCollapsed ? 'collapsed' : ''}`}>
        <div className="sidebar-loading">
          <div className="loading-spinner">⏳</div>
          {!sidebarCollapsed && <span>Loading...</span>}
        </div>
      </div>
    );
  }

  // Show error state
  if (error) {
    return (
      <div className={`sidebar ${sidebarCollapsed ? 'collapsed' : ''}`}>
        <div className="sidebar-error">
          <div className="error-icon">⚠️</div>
          {!sidebarCollapsed && <span>{error}</span>}
        </div>
      </div>
    );
  }

  return (
    <div className={`sidebar ${sidebarCollapsed ? 'collapsed' : ''}`}>
      {/* Sidebar Header */}
      <div className="sidebar-header">
        <div className="logo">
          <OmnisearchIcon
            size={sidebarCollapsed ? 28 : 24}
            className="logo-icon"
          />
          {!sidebarCollapsed && <span className="logo-text">Omnisearch</span>}
        </div>
        <button
          className="toggle-btn"
          onClick={handleToggle}
          aria-label={sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          {sidebarCollapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
        </button>
      </div>

      {/* Main Navigation */}
      <nav className="sidebar-nav" role="navigation" aria-label="Main navigation">
        <ul className="nav-list">
          {navigationItems.map((item: NavigationItem) => {
            const IconComponent = IconComponents[item.icon as keyof typeof IconComponents];
            return (
              <li key={item.id} className="nav-item">
                <button
                  className={`nav-link ${isActivePath(item.path) ? 'active' : ''}`}
                  onClick={() => handleNavigation(item.path)}
                  title={sidebarCollapsed ? item.label : ''}
                  aria-label={item.label}
                >
                  <IconComponent className="nav-icon" size={20} />
                  {!sidebarCollapsed && <span className="nav-label">{item.label}</span>}
                </button>
              </li>
            );
          })}
        </ul>
      </nav>

      {/* Quick Filters Section - Only show on search page */}
      {!sidebarCollapsed && isActivePath('/search') && (
        <div className="sidebar-section">
          <h3 className="section-title">
            <Filter className="section-icon" size={16} />
            Quick Filters
          </h3>

          <div className="filter-group">
            <label className="filter-label" htmlFor="file-type-filter">
              File Type
            </label>
            <select
              id="file-type-filter"
              className="filter-select"
              value={activeFilters.fileType || ''}
              onChange={(e) => updateFilter('fileType', e.target.value)}
            >
              <option value="">All Types</option>
              <option value="pdf">PDF</option>
              <option value="docx">Word</option>
              <option value="pptx">PowerPoint</option>
              <option value="txt">Text</option>
            </select>
          </div>

          <div className="filter-group">
            <label className="filter-label" htmlFor="date-range-filter">
              Date Range
            </label>
            <select
              id="date-range-filter"
              className="filter-select"
              value={activeFilters.dateRange || ''}
              onChange={(e) => updateFilter('dateRange', e.target.value)}
            >
              <option value="">All Time</option>
              <option value="7d">Last 7 days</option>
              <option value="30d">Last 30 days</option>
              <option value="1y">Last year</option>
            </select>
          </div>
        </div>
      )}

      {/* Sidebar Footer */}
      <div className="sidebar-footer">
        {!sidebarCollapsed && session?.user && (
          <div className="user-info">
            <div className="user-avatar">
              <User size={20} />
            </div>
            <div className="user-details">
              <span className="user-name">{session.user.name || session.user.email}</span>
              <span className="user-role">{session.user.email}</span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Sidebar;
export type { SidebarProps, NavigationItem, ActiveFilters };