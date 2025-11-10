'use client'

import React, { useState, useEffect, useRef } from 'react';
import { useSession, signOut } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import { Menu, User, Settings, LogOut, UserCircle, ChevronDown } from 'lucide-react';
import Sidebar from '../sidebar/sidebar';
import './layout.css';

interface LayoutProps {
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState<boolean>(false);
  const [showProfileMenu, setShowProfileMenu] = useState<boolean>(false);
  const profileMenuRef = useRef<HTMLDivElement>(null);
  const { data: session } = useSession();
  const router = useRouter();

  const toggleSidebar = () => {
    setIsSidebarCollapsed(prev => !prev);
  };

  const toggleProfileMenu = () => {
    setShowProfileMenu(prev => !prev);
  };

  const handleSignOut = async () => {
    await signOut({ redirect: false });
    router.push('/auth/signin');
  };

  const handleProfileClick = () => {
    setShowProfileMenu(false);
    router.push('/profile');
  };

  const handleSettingsClick = () => {
    setShowProfileMenu(false);
    router.push('/settings');
  };

  // Close profile menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (profileMenuRef.current && !profileMenuRef.current.contains(event.target as Node)) {
        setShowProfileMenu(false);
      }
    };

    if (showProfileMenu) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [showProfileMenu]);

  return (
    <div className="layout">
      {/* Sidebar */}
      <Sidebar
        isCollapsed={isSidebarCollapsed}
        onToggle={toggleSidebar}
      />

      {/* Main Content Area */}
      <main className={`main-content ${isSidebarCollapsed ? 'sidebar-collapsed' : 'sidebar-expanded'}`}>
        {/* Top Navigation Bar */}
        <header className="top-nav">
          <div className="nav-left">
            <button
              className="sidebar-toggle-btn"
              onClick={toggleSidebar}
              aria-label="Toggle sidebar"
            >
              <Menu size={20} />
            </button>
          </div>

          <div className="nav-right">
            <div className="user-menu" ref={profileMenuRef}>
              <button
                className="user-menu-btn"
                onClick={toggleProfileMenu}
              >
                <div className="user-avatar">
                  <User size={16} />
                </div>
                <span className="user-name">{session?.user?.name || 'User'}</span>
                <ChevronDown size={14} className={`transition-transform ${showProfileMenu ? 'rotate-180' : ''}`} />
              </button>

              {/* Profile Dropdown */}
              {showProfileMenu && (
                <div className="profile-dropdown">
                  <div className="profile-dropdown-header">
                    <div className="profile-avatar">
                      <User size={20} />
                    </div>
                    <div className="profile-info">
                      <p className="profile-name">{session?.user?.name || 'User'}</p>
                      <p className="profile-email">{session?.user?.email || 'user@example.com'}</p>
                    </div>
                  </div>

                  <div className="profile-dropdown-divider"></div>

                  <div className="profile-dropdown-menu">
                    <button className="profile-menu-item" onClick={handleProfileClick}>
                      <UserCircle size={16} />
                      <span>Profile</span>
                    </button>
                    <button className="profile-menu-item" onClick={handleSettingsClick}>
                      <Settings size={16} />
                      <span>Settings</span>
                    </button>
                  </div>

                  <div className="profile-dropdown-divider"></div>

                  <div className="profile-dropdown-menu">
                    <button
                      className="profile-menu-item text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20"
                      onClick={handleSignOut}
                    >
                      <LogOut size={16} />
                      <span>Sign Out</span>
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* Page Content */}
        <div className="page-content">
          {children}
        </div>
      </main>

      {/* Mobile Overlay */}
      {!isSidebarCollapsed && (
        <div
          className="mobile-overlay"
          onClick={toggleSidebar}
          aria-hidden="true"
        />
      )}
    </div>
  );
};

export default Layout;