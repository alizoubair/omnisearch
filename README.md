# 🔍 Omnisearch - AI-Powered Document Search App

Omnisearch is a modern, cloud-native application that enables users to search, discover, and interact with documents using advanced AI technologies. Built with a 3-tier architecture on Azure, it provides semantic search, AI-powered Q&A, and real-time document conversations.

## 🌟 Features

- **🔎 Semantic Search**: Find documents by meaning, not just keywords using Azure AI Search
- **🤖 AI-Powered Q&A**: Ask questions about document content with OpenAI integration
- **📄 Multi-format Support**: PDF, Word, PowerPoint, and text files
- **💬 Real-time Chat**: Interactive document conversations with citation tracking
- **☁️ Cloud-Native**: Fully deployed on Azure with Infrastructure as Code
- **🚀 Scalable Architecture**: 3-tier architecture with auto-scaling capabilities
- **🔒 Secure**: Network isolation, Key Vault integration, and secure authentication

## 🏗️ Architecture

Omnisearch follows a **3-tier architecture** deployed on Azure:

### Components

- **Frontend**: Next.js 14 with TypeScript, Tailwind CSS, and Radix UI
- **Backend**: FastAPI with async PostgreSQL, SQLAlchemy, and Alembic
- **Database**: PostgreSQL Flexible Server with private networking
- **AI Services**: Azure OpenAI, Document Intelligence, and AI Search
- **Infrastructure**: Terraform-managed Azure resources
- **CI/CD**: Azure DevOps pipelines with self-hosted agents

## 📁 Project Structure

```
omnisearch/
├── frontend/                    # Next.js frontend application
│   ├── src/                    # Source code
│   │   ├── app/               # Next.js app directory
│   │   ├── components/        # React components
│   │   └── lib/              # Utilities
│   ├── Dockerfile             # Container configuration
│   └── README.md              # Frontend documentation
│
├── backend/                    # FastAPI backend application
│   ├── app/                   # Application code
│   │   ├── api/              # API routes
│   │   ├── core/             # Core functionality
│   │   ├── models/           # Database models
│   │   ├── schemas/          # Pydantic schemas
│   │   └── services/         # Business logic
│   ├── Dockerfile            # Container configuration
│   └── README.md             # Backend documentation
│
├── infrastructure/             # Infrastructure as Code
│   ├── terraform/            # Terraform configurations
│   │   ├── modules/         # Reusable Terraform modules
│   │   │   ├── networking/  # VNet, subnets, NSGs
│   │   │   ├── compute/     # VM Scale Sets
│   │   │   ├── database/    # PostgreSQL
│   │   │   ├── ai-services/ # Azure AI services
│   │   │   └── ...         # Other modules
│   │   ├── environments/    # Environment configs
│   │   └── README.md        # Infrastructure docs
│   └── pipelines/           # CI/CD pipelines
│       ├── azure-pipelines-frontend.yml
│       └── azure-pipelines-backend.yml
│
└── scripts/                     # Utility scripts
    └── install-devops-agent.sh # DevOps agent setup
```

## 🚀 Quick Start

### Prerequisites

- **Azure Subscription** with appropriate permissions
- **Azure CLI** installed and configured
- **Terraform** >= 1.6.0
- **Docker** (for local development)
- **Node.js** 18+ (for frontend development)
- **Python** 3.12+ (for backend development)

### Local Development

#### 1. Clone the Repository

```bash
git clone https://github.com/alizoubair/omnisearch.git
cd omnisearch
```

#### 2. Set Up Backend

```bash
cd backend
python3.12 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Run the application
python run.py
```

The API will be available at:
- **API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs

See [backend/README.md](backend/README.md) for detailed backend documentation.

#### 3. Set Up Frontend

```bash
cd frontend
npm install

# Set up environment variables
cp .env.example .env.local
# Edit .env.local with your configuration

# Start development server
npm run dev
```

The frontend will be available at http://localhost:3000

See [frontend/README.md](frontend/README.md) for detailed frontend documentation.

### Infrastructure Deployment

#### 1. Configure Terraform

```bash
cd infrastructure/terraform

# Copy example configuration
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars

# Edit terraform.tfvars with your Azure configuration
# Required: subscription_id, tenant_id, service_principal credentials
```

#### 2. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply the infrastructure
terraform apply -var-file=environments/dev/terraform.tfvars
```

This will create:
- Virtual Network with subnets
- VM Scale Sets for frontend and backend
- PostgreSQL Flexible Server
- Azure AI Services (OpenAI, Document Intelligence, AI Search)
- Application Gateway and Load Balancers
- Azure Container Registry
- Azure Key Vault
- Azure DevOps resources

See [infrastructure/terraform/README.md](infrastructure/terraform/README.md) for detailed infrastructure documentation.

## 🛠️ Tech Stack

### Frontend
- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **UI Components**: Radix UI
- **State Management**: Zustand
- **Authentication**: NextAuth.js

### Backend
- **Framework**: FastAPI
- **Language**: Python 3.12
- **Database**: PostgreSQL with asyncpg
- **ORM**: SQLAlchemy (async)
- **Migrations**: Alembic
- **Authentication**: JWT tokens

### Infrastructure
- **IaC**: Terraform
- **Cloud Provider**: Microsoft Azure
- **Container Registry**: Azure Container Registry (ACR)
- **CI/CD**: Azure DevOps
- **Monitoring**: Log Analytics, Application Insights

### AI Services
- **Search**: Azure AI Search
- **LLM**: Azure OpenAI (GPT-4)
- **Document Processing**: Azure Document Intelligence

## 🔧 Configuration

### Environment Variables

#### Backend
- `DATABASE_URL`: PostgreSQL connection string
- `SECRET_KEY`: JWT secret key
- `OPENAI_API_KEY`: Azure OpenAI API key
- `AZURE_SEARCH_ENDPOINT`: Azure AI Search endpoint
- `AZURE_SEARCH_KEY`: Azure AI Search key
- `AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT`: Document Intelligence endpoint
- `AZURE_DOCUMENT_INTELLIGENCE_KEY`: Document Intelligence key

#### Frontend
- `NEXT_PUBLIC_API_BASE_URL`: Backend API URL
- `NEXTAUTH_SECRET`: NextAuth secret
- `NEXTAUTH_URL`: Frontend URL
- `DATABASE_URL`: PostgreSQL connection string (for NextAuth)

### Terraform Variables

Key variables in `terraform.tfvars`:
- `resource_group_name`: Azure resource group
- `location`: Azure region
- `subscription_id`: Azure subscription ID
- `tenant_id`: Azure tenant ID
- `service_principal_*`: Service principal credentials
- `ssh_public_key`: SSH public key for VM access

See [infrastructure/terraform/environments/dev/terraform.tfvars.example](infrastructure/terraform/environments/dev/terraform.tfvars.example) for all available variables.

## 🚢 Deployment

### CI/CD Pipeline

The project uses Azure DevOps pipelines for automated deployment:

1. **Build Stage**: 
   - Builds Docker images
   - Pushes to Azure Container Registry
   - Runs tests

2. **Deploy Stage**:
   - Deploys to VM Scale Sets
   - Runs database migrations
   - Updates load balancer configurations

Pipelines are defined in:
- `infrastructure/pipelines/azure-pipelines-frontend.yml`
- `infrastructure/pipelines/azure-pipelines-backend.yml`

### Manual Deployment

```bash
# Build and push Docker images
cd backend
docker build -t <acr-name>.azurecr.io/omnisearch-backend:latest .
docker push <acr-name>.azurecr.io/omnisearch-backend:latest

cd ../frontend
docker build -t <acr-name>.azurecr.io/omnisearch-frontend:latest .
docker push <acr-name>.azurecr.io/omnisearch-frontend:latest
```

## 📊 Monitoring

- **Application Insights**: Application performance monitoring
- **Log Analytics**: Centralized logging
- **Health Endpoints**: 
  - Frontend: `/api/health`
  - Backend: `/api/health` and `/api/health/db`

## 🔒 Security

- **Network Isolation**: Private subnets with NSGs
- **Secrets Management**: Azure Key Vault
- **Authentication**: JWT tokens with NextAuth.js
- **HTTPS**: Application Gateway with SSL/TLS
- **Firewall Rules**: Database firewall and NSG rules
- **Private Endpoints**: Database and Key Vault use private networking

---

**Built with ❤️ using Azure, Next.js, and FastAPI**

