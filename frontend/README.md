# Omnisearch Frontend

## 🔍 AI-Powered Document Search App

Omnisearch is a modern web application that enables users to search, discover, and interact with documents using advanced AI technologies.

## 🚀 Features

- **Semantic Search**: Find documents by meaning, not just keywords
- **AI-Powered Q&A**: Ask questions about document content
- **Multi-format Support**: PDF, Word, PowerPoint, text files
- **Real-time Chat**: Interactive document conversations
- **Citation Tracking**: Reference source documents in answers

## 🛠️ Tech Stack

- **Framework**: Next.js 14 with TypeScript
- **Styling**: Tailwind CSS
- **UI Components**: Radix UI
- **State Management**: Zustand
- **Authentication**: NextAuth.js
- **Database**: PostgreSQL with Drizzle ORM

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- PostgreSQL database
- Azure AI services (OpenAI, AI Search, Document Intelligence)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd omnisearch/frontend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env.local
   ```

4. **Configure environment variables**
   ```env
   # Database
   DATABASE_URL="postgresql://username:password@localhost:5432/omnisearch_dev"
   
   # NextAuth
   NEXTAUTH_SECRET="your-secret-key"
   NEXTAUTH_URL="http://localhost:3000"
   
   # Backend API
   NEXT_PUBLIC_API_URL="http://localhost:8000"
   
   # Azure AI Services
   NEXT_PUBLIC_AZURE_SEARCH_ENDPOINT="https://omnisearch-search-dev.search.windows.net"
   NEXT_PUBLIC_AZURE_OPENAI_ENDPOINT="https://omnisearch-openai-dev.openai.azure.com"
   ```

5. **Set up database**
   ```bash
   npm run docker:up
   npm run db:migrate
   npm run db:seed
   ```

6. **Start development server**
   ```bash
   npm run dev
   ```

7. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## 📁 Project Structure

```
frontend/
├── src/
│   ├── app/                 # Next.js app directory
│   │   ├── (auth)/         # Authentication pages
│   │   ├── api/            # API routes
│   │   ├── chat/           # Chat interface
│   │   ├── search/         # Search interface
│   │   └── upload/         # Document upload
│   ├── components/         # Reusable components
│   │   ├── ui/            # UI components
│   │   ├── search/        # Search components
│   │   ├── chat/          # Chat components
│   │   └── layout/        # Layout components
│   ├── lib/               # Utilities and configurations
│   ├── hooks/             # Custom React hooks
│   ├── store/             # Zustand stores
│   └── types/             # TypeScript type definitions
├── public/                # Static assets
```

## 🔧 Available Scripts

### Development
```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
npm run type-check   # Run TypeScript checks
```

### Database
```bash
npm run db:setup     # Set up new database
npm run db:migrate   # Run database migrations
npm run db:seed      # Seed database with sample data
npm run db:studio    # Open Drizzle Studio
npm run db:reset     # Reset database completely
```

### Docker
```bash
npm run docker:up    # Start PostgreSQL container
npm run docker:down  # Stop PostgreSQL container
npm run docker:logs  # View PostgreSQL logs
npm run docker:reset # Reset PostgreSQL container
```

## 🎨 UI Components

Omnisearch uses a modern, accessible design system built with:

- **Radix UI**: Headless, accessible components
- **Tailwind CSS**: Utility-first CSS framework
- **Lucide React**: Beautiful, customizable icons
- **Dark/Light Mode**: Theme switching support

### Key Components
- `SearchInterface`: Main document search interface
- `DocumentViewer`: PDF and document preview
- `ChatInterface`: AI-powered document chat
- `UploadZone`: Drag-and-drop file upload
- `ResultsGrid`: Search results display

## 🚀 Deployment

### Development
```bash
npm run build
npm run start
```

### Production (Azure)
The frontend is deployed as part of the Omnisearch infrastructure:

```bash
# Deploy to Azure VM Scale Set
cd ../infrastructure/terraform/environments/dev
terraform apply -var-file="terraform.tfvars"
```

### Docker
```bash
docker build -t omnisearch-frontend .
docker run -p 3000:3000 omnisearch-frontend
```

## 🔧 Configuration

### Environment Variables
- `DATABASE_URL`: PostgreSQL connection string
- `NEXTAUTH_SECRET`: Authentication secret
- `NEXT_PUBLIC_API_URL`: Backend API endpoint
- `NEXT_PUBLIC_AZURE_*`: Azure AI service endpoints

### Tailwind Configuration
Custom design tokens and components in `tailwind.config.js`

### TypeScript Configuration
Strict TypeScript configuration in `tsconfig.json`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is part of the Omnisearch AI Document Search platform.

---

**Omnisearch Frontend** - Empowering users to discover, understand, and interact with documents through advanced AI technology. 🔍📄🤖