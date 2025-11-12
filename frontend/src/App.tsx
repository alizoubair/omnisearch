import React from 'react';
import { NavigationProvider, useNavigation } from './contexts/NavigationContext';
import Layout from './components/layout/layout';
import './App.css';

// Import existing components (using named exports)
import { DocumentLibrary } from './components/documents/document-library';
import { SearchInterface } from './components/search/search-interface';
import { ChatInterface } from './components/chat/chat-interface';

// Main app content component
const AppContent: React.FC = () => {
  const { currentPage } = useNavigation();

  // Page renderer using navigation context
  const renderCurrentPage = () => {
    switch (currentPage) {
      case 'documents':
        return (
          <Layout>
            <DocumentLibrary />
          </Layout>
        );
      case 'search':
        return (
          <Layout>
            <SearchInterface />
          </Layout>
        );
      case 'chat':
        return (
          <Layout>
            <ChatInterface />
          </Layout>
        );
      default:
        return (
          <Layout>
            <DocumentLibrary />
          </Layout>
        );
    }
  };

  return <div className="app">{renderCurrentPage()}</div>;
};

// Main App component with providers
const App: React.FC = () => {
  return (
    <NavigationProvider>
      <AppContent />
    </NavigationProvider>
  );
};

export default App;