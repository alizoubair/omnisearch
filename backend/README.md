# Omnisearch Backend API - FastAPI Application

This is the backend API for **Omnisearch**, an AI-powered document search app built with FastAPI, PostgreSQL, and Azure AI services.

## 🚀 Quick Start

### Using Docker (Recommended)

```bash
# Build the Docker image
docker build -t omnisearch-backend .

# Run the container
docker run -d \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql://user:password@host:5432/dbname \
  -e SECRET_KEY=your-secret-key \
  omnisearch-backend

# View logs
docker logs -f <container-id>

# Stop container
docker stop <container-id>
```

The API will be available at:
- **API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs

### Manual Setup

```bash
# Create virtual environment
python3.12 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Run the application
python run.py
```

## 📁 Project Structure

```
backend/
├── app/                    # Application code
│   ├── api/               # API routes
│   ├── core/              # Core functionality (config, database, security)
│   ├── models/            # Database models
│   ├── schemas/           # Pydantic schemas
│   ├── services/          # Business logic
│   ├── main.py           # FastAPI application
│   └── init-omnisearch-db.sql # Database initialization script
├── Dockerfile             # Container configuration
├── requirements.txt       # Python dependencies
├── run.py                 # Application entry point
└── README.md              # This file
```

## 🐳 Docker Configuration

### Dockerfile Features
- **Multi-stage build** for optimized production images
- **Non-root user** for security
- **Health checks** for container orchestration
- **Environment variables** for configuration

### Building and Running

```bash
# Build the Docker image
docker build -t omnisearch-backend .

# Run with environment variables
docker run -d \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql://user:password@host:5432/dbname \
  -e SECRET_KEY=your-secret-key \
  -e OPENAI_ENDPOINT=your-openai-endpoint \
  -e OPENAI_API_KEY=your-openai-key \
  omnisearch-backend

# Or use a .env file
docker run -d \
  -p 8000:8000 \
  --env-file .env \
  omnisearch-backend
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://...` |
| `SECRET_KEY` | JWT secret key | `your-secret-key` |
| `ENVIRONMENT` | Application environment | `development` |
| `DEBUG` | Enable debug mode | `false` |
| `CORS_ORIGINS` | Allowed CORS origins | `*` |

### Database Configuration

The application uses PostgreSQL with the following features:
- **Async connections** with asyncpg
- **Connection pooling** for performance
- **Migrations** with Alembic
- **UUID primary keys** for security

## 📊 API Documentation

### Interactive Documentation
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI Schema**: http://localhost:8000/openapi.json

### Key Endpoints

#### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/refresh` - Refresh JWT token

#### Users
- `GET /api/users/me` - Get current user
- `PUT /api/users/me` - Update current user

#### Documents
- `GET /api/documents/` - List user documents
- `POST /api/documents/` - Upload document
- `GET /api/documents/{id}` - Get document details
- `DELETE /api/documents/{id}` - Delete document

#### Chat
- `GET /api/chat/sessions` - List chat sessions
- `POST /api/chat/sessions` - Create chat session
- `POST /api/chat/sessions/{id}/messages` - Send message

#### Health
- `GET /api/health` - Application health check
- `GET /api/health/db` - Database health check

## 🚀 Deployment

### Azure Container Instances
The application is deployed using Azure Container Instances with:
- **Auto-scaling** based on CPU usage
- **Health monitoring** with custom health checks
- **Environment-specific** configuration
- **Secrets management** with Azure Key Vault

### CI/CD Pipeline
The `azure-pipelines.yml` includes:
1. **Build stage**: Install dependencies, run tests, create container
2. **Deploy to Dev**: Automatic deployment to development

### Container Registry
Images are stored in Azure Container Registry with:
- **Vulnerability scanning** enabled
- **Image signing** for security
- **Retention policies** for cleanup