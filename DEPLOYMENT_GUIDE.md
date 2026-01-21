# Moat-Chat Bot - Infrastructure Deployment Package Guide

**Version:** 1.0
**Last Updated:** January 2026
**Repository:** https://bitbucket.org/moatdevelopers/moat-policy-chat-bot
**Application:** Moat-Chat Bot (RAG-based Document QA System)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [What You're Deploying](#what-youre-deploying)
3. [Step-by-Step Packaging Instructions](#step-by-step-packaging-instructions)
4. [Deployment Options](#deployment-options)
5. [Configuration Requirements](#configuration-requirements)
6. [Infrastructure Requirements](#infrastructure-requirements)
7. [Deployment Checklist](#deployment-checklist)
8. [Testing & Validation](#testing--validation)
9. [Troubleshooting](#troubleshooting)
10. [Support & Contacts](#support--contacts)

---

## 1. Executive Summary

**What is this application?**
Moat-Chat Bot is a Retrieval-Augmented Generation (RAG) web application that allows users to upload documents and chat with them using Large Language Models (LLMs). It features:
- Web-based UI for document upload and Q&A
- Integration with OpenAI, Azure OpenAI, and local LLMs
- Vector search and graph-based retrieval (LightRAG)
- Document processing for PDFs, Word docs, spreadsheets, etc.
- Persistent storage for conversations and uploaded files

**Current Status:**
✅ Docker image built and tested locally
✅ Running successfully on development laptop
✅ Code committed to GitHub repository
✅ Ready for infrastructure team handoff

---

## 2. What You're Deploying

### Application Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Moat-Chat Bot Container                   │
├─────────────────────────────────────────────────────────────┤
│  Web Server (Gradio on port 7860)                           │
│  ├── Frontend: Document upload, chat interface              │
│  └── Backend: FastAPI/Uvicorn                               │
├─────────────────────────────────────────────────────────────┤
│  RAG Pipeline                                                │
│  ├── Document Parser (PDF, Word, Excel, etc.)               │
│  ├── Vector Store (ChromaDB) - for embeddings               │
│  ├── Document Store (LanceDB) - for metadata                │
│  ├── LLM Integration (OpenAI/Azure/Local)                   │
│  └── LightRAG (Graph-based retrieval)                       │
├─────────────────────────────────────────────────────────────┤
│  Persistence Layer                                           │
│  └── SQLite Database (user data, conversations, settings)   │
└─────────────────────────────────────────────────────────────┘
                             ↓
                    Persistent Volume
              /app/ktem_app_data (CRITICAL!)
```

### Key Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Web UI** | Gradio 4.31+ | User interface for chat and document management |
| **Backend** | FastAPI, Python 3.10 | API server and business logic |
| **Database** | SQLite (default) | User data, conversations, application settings |
| **Vector Store** | ChromaDB | Document embeddings for semantic search |
| **Document Store** | LanceDB | Document metadata and chunks |
| **LLM Provider** | OpenAI/Azure OpenAI | Language model API for chat responses |
| **OCR/Parsing** | Tesseract, Poppler, LibreOffice | Document processing tools |

---

## 3. Getting Started - Quick Deployment

The code is already available in the Bitbucket repository. Follow these steps to deploy:

### Step 1: Clone the Repository

```bash
# Clone from Bitbucket
git clone https://bitbucket.org/moatdevelopers/moat-policy-chat-bot.git
cd moat-policy-chat-bot
```

### Step 2: Configure Environment Variables

Create your `.env` file with the required API keys:

```bash
# Create .env file from template
cp .env.template .env

# Edit .env and add your API keys
# Use your preferred text editor (nano, vim, notepad, etc.)
nano .env
```

**IMPORTANT: Obtaining API Credentials**

The application requires LLM API keys to function. These credentials are **NOT** included in the repository for security reasons.

**Azure OpenAI Credentials (Recommended for this deployment):**
- Contact the development team to obtain:
  - `AZURE_OPENAI_ENDPOINT`
  - `AZURE_OPENAI_API_KEY`
- These will be shared via secure channel (password manager, encrypted email, or in-person)
- Alternatively, provision your own Azure OpenAI resource from Azure Portal

**Alternative: Use OpenAI (if Azure not available):**
- Sign up at https://platform.openai.com/
- Generate API key at https://platform.openai.com/api-keys
- Add to `.env` as `OPENAI_API_KEY`

**Minimum required configuration** - Add at least ONE LLM provider:

```bash
# Option 1: OpenAI (Recommended)
OPENAI_API_KEY=sk-proj-your-key-here
OPENAI_API_BASE=https://api.openai.com/v1
OPENAI_CHAT_MODEL=gpt-4o-mini
OPENAI_EMBEDDINGS_MODEL=text-embedding-3-large

# Option 2: Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_KEY=your-key-here
OPENAI_API_VERSION=2024-08-01-preview
AZURE_OPENAI_CHAT_DEPLOYMENT=gpt-4o
AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT=text-embedding-3-large

# Option 3: Local Models (requires Ollama server)
LOCAL_MODEL=qwen2.5:7b
LOCAL_MODEL_EMBEDDINGS=nomic-embed-text
KH_OLLAMA_URL=http://localhost:11434/v1/
```

### Step 3: Deploy the Application

Choose one of the deployment methods below:

#### **Option A: Single-Node Deployment (Development/Small Teams)**

```bash
# Build and start the application
# Note: This will automatically build the Docker image if it doesn't exist
docker-compose up -d

# View logs (to monitor startup progress)
docker-compose logs -f

# Access the application
# Open browser: http://localhost:7860
```

**What happens during first deployment:**
1. Docker reads `docker-compose.yml`
2. Checks if image `moat-chat-bot:latest` exists locally
3. If NOT found, automatically builds from `Dockerfile.optimized` (takes ~5-10 minutes first time)
4. Starts the container
5. Application initializes and becomes available on port 7860

**For subsequent restarts:**
```bash
# Use existing image (fast restart)
docker-compose restart

# Or rebuild if code changed
docker-compose up -d --build
```

#### **Option B: High-Availability Deployment (Production)**

```bash
# Initialize Docker Swarm (if not already done)
docker swarm init

# Export environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Deploy the stack
docker stack deploy -c docker-stack.yml moat-chat

# Check deployment status
docker stack services moat-chat
docker stack ps moat-chat

# Access the application
# Open browser: http://<any-node-ip>:7860
```

### Step 4: Verify Deployment

```bash
# Check if container is running
docker ps | grep moat-chat

# Check application health
curl http://localhost:7860/

# View application logs
docker logs <container-id>

# Expected output: "Running on http://0.0.0.0:7860"
```

### Step 5: First-Time Setup

1. **Access the web interface:** Open http://localhost:7860 in your browser
2. **Upload a test document:** Click upload and select a PDF file
3. **Ask a question:** Type a question about the document
4. **Verify response:** Ensure the LLM responds with citations

**That's it!** The application is now running and ready to use.

---

### Alternative: Building Custom Docker Image

If you need to build the Docker image yourself (e.g., for customizations):

```bash
# Build the optimized image
docker build -f Dockerfile.optimized -t moat-chat-bot:latest .

# Then deploy using docker-compose or docker stack as shown above
docker-compose up -d
```

---

## 4. Deployment Options

Your infrastructure team can choose from three deployment strategies:

### Option A: Single-Node Docker Compose (Recommended for Development/Small Teams)

**Use when:**
- Development or staging environment
- Small team (<10 users)
- No high-availability requirements
- Simple to manage

**Deployment:**
```bash
docker-compose up -d
```

**Pros:**
- Easy to set up and manage
- Quick startup
- Simple troubleshooting

**Cons:**
- No redundancy (single point of failure)
- No automatic failover
- Limited scaling

### Option B: Docker Swarm High-Availability (Recommended for Production)

**Use when:**
- Production environment
- Multiple users
- High-availability required
- Zero-downtime deployments needed

**Deployment:**
```bash
docker swarm init
export $(grep -v '^#' .env | xargs)
docker stack deploy -c docker-stack.yml moat-chat
```

**Pros:**
- 2+ replicas for redundancy
- Rolling updates with automatic rollback
- Load balancing across replicas
- Health checks with automatic replacement

**Cons:**
- More complex setup
- Requires Swarm cluster
- Shared storage needed for multi-node (or use node constraints)

### Option C: Platform as a Service (Fly.io, Cloud Run, etc.)

**Use when:**
- Minimal operational overhead desired
- Auto-scaling required
- Managed infrastructure preferred

**Deployment:**
Requires platform-specific configuration (fly.toml provided in repo)

---

## 5. Configuration Requirements

### Mandatory Configuration

**Environment Variables (`.env` file):**

At minimum, configure ONE LLM provider:

```bash
# Option 1: OpenAI
OPENAI_API_KEY=sk-proj-xxxxx
OPENAI_API_BASE=https://api.openai.com/v1
OPENAI_CHAT_MODEL=gpt-4o-mini
OPENAI_EMBEDDINGS_MODEL=text-embedding-3-large

# Option 2: Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_KEY=your-key-here
AZURE_OPENAI_CHAT_DEPLOYMENT=gpt-4o
AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT=text-embedding-3-large
OPENAI_API_VERSION=2024-08-01-preview

# Option 3: Local Models (requires Ollama server running)
LOCAL_MODEL=qwen2.5:7b
LOCAL_MODEL_EMBEDDINGS=nomic-embed-text
KH_OLLAMA_URL=http://localhost:11434/v1/
```

### Optional Configuration

**Advanced Features:**
```bash
# Enable graph-based retrieval (recommended)
USE_LIGHTRAG=true
GRAPHRAG_API_KEY=sk-proj-xxxxx
GRAPHRAG_LLM_MODEL=gpt-4o-mini
```

**Authentication (currently disabled):**
```bash
# To enable Google OAuth:
AUTHENTICATION_METHOD=
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-secret

# To enable Keycloak:
AUTHENTICATION_METHOD=KEYCLOAK
KEYCLOAK_SERVER_URL=https://your-keycloak.com
KEYCLOAK_CLIENT_ID=moat-chat
KEYCLOAK_REALM=master
KEYCLOAK_CLIENT_SECRET=your-secret
```

### Application Configuration

**File:** `flowsettings.py` (already configured, no changes needed)

Key settings already set:
- `KH_FEATURE_USER_MANAGEMENT = False` - Login disabled
- `KH_APP_DATA_DIR = "./ktem_app_data"` - Data directory
- `USE_LIGHTRAG = true` - Graph retrieval enabled

---

## 6. Infrastructure Requirements

### Compute Resources

| Deployment Type | CPU | Memory | Storage | Network |
|----------------|-----|--------|---------|---------|
| **Development** | 2 cores | 4 GB | 20 GB | 10 Mbps |
| **Production (per replica)** | 2-4 cores | 8 GB | 50-100 GB | 50 Mbps |
| **High-Load** | 4-8 cores | 16 GB | 200+ GB | 100 Mbps |

### Network Requirements

**Inbound:**
- Port 7860/TCP - Web application (HTTP)
- Recommend placing behind reverse proxy (Nginx/Traefik) for HTTPS

**Outbound:**
- Port 443/TCP - HTTPS for API calls to:
  - `api.openai.com` (if using OpenAI)
  - `*.openai.azure.com` (if using Azure OpenAI)
  - Other LLM providers as configured

### Storage Requirements

**Persistent Volume:** `/app/ktem_app_data`

This directory contains ALL user data and MUST be persisted:

```
ktem_app_data/
├── user_data/
│   ├── sql.db              # SQLite database (conversations, users, settings)
│   ├── files/              # Uploaded documents (grows with usage)
│   ├── docstore/           # LanceDB document metadata
│   └── vectorstore/        # ChromaDB vector embeddings (largest)
├── chunks_cache_dir/       # Cached document chunks
├── markdown_cache_dir/     # Cached markdown outputs
└── gradio_tmp/             # Temporary UI files
```

**Storage Growth:**
- Base: ~1 GB (empty database + caches)
- Per 1000 documents: ~5-10 GB (varies by document size)
- Vector store growth: ~1-2 GB per 100,000 pages

**Backup Strategy:**
- Frequency: Daily (minimum), hourly (recommended for production)
- Retention: 7-30 days
- Method: Snapshot entire `ktem_app_data/` directory
- Test restores: Monthly

### System Dependencies

Included in Docker image (no action needed):
- Python 3.10
- Tesseract OCR
- Poppler (PDF utilities)
- LibreOffice (document conversion)
- FFmpeg (media processing)
- curl (health checks)

---

## 7. Deployment Checklist

Use this checklist for the infrastructure team:

### Pre-Deployment

- [ ] **Environment prepared**
  - [ ] Docker 20.10+ installed
  - [ ] Docker Compose 2.0+ installed (single-node) OR Docker Swarm initialized (HA)
  - [ ] Minimum resources allocated (see requirements above)

- [ ] **Configuration completed**
  - [ ] `.env` file created from template
  - [ ] At least one LLM provider API key configured
  - [ ] API keys tested and validated

- [ ] **Storage configured**
  - [ ] Persistent volume created for `/app/ktem_app_data`
  - [ ] Minimum 50GB allocated (100GB recommended)
  - [ ] Backup solution configured

- [ ] **Network configured**
  - [ ] Port 7860 accessible (or configured alternative)
  - [ ] Outbound HTTPS allowed to LLM provider endpoints
  - [ ] Reverse proxy configured (if using HTTPS)

### Deployment

- [ ] **Image deployed**
  - [ ] Docker image loaded/pulled successfully
  - [ ] Image version verified: `docker images | grep moat-chat-bot`

- [ ] **Application started**
  - [ ] Single-node: `docker-compose up -d` executed
  - [ ] OR HA: `docker stack deploy -c docker-stack.yml moat-chat` executed
  - [ ] Containers running: `docker ps` shows healthy status

- [ ] **Health checks passing**
  - [ ] Application accessible: `curl http://localhost:7860/`
  - [ ] Web UI loads in browser
  - [ ] No errors in logs: `docker logs <container-id>`

### Post-Deployment Validation

- [ ] **Functional testing**
  - [ ] Can access web UI at http://[server-ip]:7860
  - [ ] Can upload a test document (e.g., PDF)
  - [ ] Can chat with uploaded document
  - [ ] LLM responses received successfully
  - [ ] Citations display correctly

- [ ] **Data persistence verified**
  - [ ] `ktem_app_data/user_data/sql.db` created
  - [ ] Uploaded files appear in `ktem_app_data/user_data/files/`
  - [ ] Container restart preserves data

- [ ] **Monitoring configured**
  - [ ] Health check endpoint monitored: `http://localhost:7860/`
  - [ ] Container logs aggregated
  - [ ] Resource usage monitored (CPU, memory, disk)
  - [ ] Alerts configured for failures

- [ ] **Backup verified**
  - [ ] First backup completed successfully
  - [ ] Backup restore tested
  - [ ] Backup schedule automated

### Production Readiness (if applicable)

- [ ] **Security hardened**
  - [ ] HTTPS configured (reverse proxy with SSL/TLS)
  - [ ] API keys stored securely (Docker Secrets if using Swarm)
  - [ ] Authentication enabled (if required)
  - [ ] Network policies applied (firewall rules)

- [ ] **High-Availability configured**
  - [ ] Multiple replicas running (minimum 2)
  - [ ] Load balancing verified
  - [ ] Failover tested (kill one replica, verify service continues)
  - [ ] Rolling update tested

- [ ] **Documentation delivered**
  - [ ] Runbook provided to operations team
  - [ ] Escalation path defined
  - [ ] Support contacts documented

---

## 8. Testing & Validation

### Basic Functionality Tests

**Test 1: Application Starts**
```bash
# Check container is running
docker ps | grep moat-chat-bot

# Check logs for successful startup
docker logs <container-id> | tail -n 50

# Expected: No errors, sees "Running on http://0.0.0.0:7860"
```

**Test 2: Web UI Accessible**
```bash
# Test from server
curl -I http://localhost:7860/

# Expected: HTTP 200 OK

# Test from browser
# Open: http://[server-ip]:7860
# Expected: Moat-Chat Bot interface loads
```

**Test 3: Document Upload & Chat**
1. Click "Upload" in the web UI
2. Select a test PDF file (e.g., company policy document)
3. Wait for processing to complete (~30 seconds for 10-page PDF)
4. Type a question: "What is this document about?"
5. Verify LLM response is generated with citations

**Test 4: Data Persistence**
```bash
# Upload a document and create a conversation (as above)

# Restart the container
docker-compose restart  # OR docker service update <service-name> --force

# Wait for startup (~30 seconds)

# Verify:
# - Uploaded document still visible in UI
# - Previous conversation still accessible
# - Can continue chatting with same document
```

### Advanced Tests (Production)

**Test 5: LLM Integration**
```bash
# Verify API calls are working
docker logs <container-id> | grep -i "openai\|azure"

# Expected: Successful API calls, no authentication errors
```

**Test 6: High-Availability Failover**
```bash
# Identify running containers
docker stack ps moat-chat

# Kill one container
docker kill <container-id>

# Verify:
# - New container starts automatically within 30 seconds
# - Service remains accessible throughout
# - No data loss
```

**Test 7: Resource Usage**
```bash
# Monitor resource consumption
docker stats <container-id>

# Expected (idle):
# - CPU: <5%
# - Memory: 2-3 GB

# Expected (under load - multiple concurrent chats):
# - CPU: 20-50%
# - Memory: 4-6 GB
```

### Performance Benchmarks

| Metric | Expected Value | Test Method |
|--------|----------------|-------------|
| **Startup Time** | <3 minutes | `docker logs` timestamp from start to "Running on" |
| **Document Upload (10-page PDF)** | <30 seconds | UI timer |
| **Chat Response Time** | 3-10 seconds | UI timer (depends on LLM) |
| **Concurrent Users** | 5-10 (single instance) | Load testing tool |
| **Memory Usage (idle)** | 2-3 GB | `docker stats` |
| **Memory Usage (active)** | 4-6 GB | `docker stats` during chat |

---

## 9. Troubleshooting

### Common Issues

#### Issue 1: Container Won't Start

**Symptoms:**
- Container exits immediately
- `docker ps` shows no running containers

**Diagnosis:**
```bash
docker logs <container-id>
```

**Common Causes & Solutions:**

| Error Message | Cause | Solution |
|---------------|-------|----------|
| `Permission denied: '/app/ktem_app_data'` | Volume mount permissions | `chmod -R 777 ktem_app_data/` (or set correct ownership) |
| `Port 7860 already in use` | Another service using port | Stop other service OR change port in docker-compose.yml |
| `OPENAI_API_KEY not set` | Missing environment variable | Verify `.env` file exists and contains API key |
| `ImportError: No module named 'ktem'` | Build issue | Rebuild image: `docker-compose build --no-cache` |

#### Issue 2: Application Accessible but LLM Not Responding

**Symptoms:**
- UI loads fine
- Can upload documents
- Chat doesn't return responses or shows errors

**Diagnosis:**
```bash
# Check logs for API errors
docker logs <container-id> | grep -i "error\|exception\|failed"
```

**Common Causes & Solutions:**

| Error Message | Cause | Solution |
|---------------|-------|----------|
| `Authentication failed` | Invalid API key | Verify API key in `.env` is correct and active |
| `Rate limit exceeded` | Too many API calls | Wait or upgrade API plan |
| `Connection timeout` | Network blocked | Check firewall allows HTTPS to `api.openai.com` |
| `Model not found` | Wrong model name | Verify `OPENAI_CHAT_MODEL` matches available models |

#### Issue 3: Data Not Persisting

**Symptoms:**
- Uploaded documents disappear after restart
- Conversations lost

**Diagnosis:**
```bash
# Check volume mount
docker inspect <container-id> | grep -A 5 "Mounts"

# Check data directory
ls -la ktem_app_data/user_data/
```

**Solution:**
- Verify volume mount in docker-compose.yml is correct
- Ensure host directory `./ktem_app_data` exists and is writable
- Check for mount errors: `docker logs <container-id> | grep -i mount`

#### Issue 4: High Memory Usage / Out of Memory

**Symptoms:**
- Container killed unexpectedly
- Slow performance
- `docker stats` shows >8GB memory usage

**Diagnosis:**
```bash
docker stats <container-id>
docker logs <container-id> | grep -i "memory\|oom"
```

**Solutions:**
- Increase Docker memory limit in docker-compose.yml
- Reduce concurrent document processing
- Clear caches: `rm -rf ktem_app_data/chunks_cache_dir/*`
- Use smaller embedding models (e.g., `text-embedding-3-small` instead of `large`)

#### Issue 5: Slow Document Processing

**Symptoms:**
- Document upload takes >5 minutes
- UI shows "Processing..." indefinitely

**Diagnosis:**
```bash
# Check CPU usage
docker stats <container-id>

# Check for errors
docker logs <container-id> | tail -n 100
```

**Solutions:**
- Ensure adequate CPU allocated (minimum 2 cores)
- Check document size (very large PDFs may take longer)
- Verify OCR not stuck: `docker exec <container-id> ps aux | grep tesseract`
- Restart container if stuck: `docker restart <container-id>`

### Getting Help

1. **Check logs first:**
   ```bash
   docker logs <container-id> --tail 200 -f
   ```

2. **Check application health:**
   ```bash
   curl http://localhost:7860/
   ```

3. **Verify configuration:**
   ```bash
   docker exec <container-id> env | grep -E "OPENAI|AZURE|KH_"
   ```

4. **Collect diagnostic information:**
   ```bash
   # System info
   docker info
   docker version

   # Container info
   docker inspect <container-id>
   docker logs <container-id> > container-logs.txt

   # Resource usage
   docker stats <container-id> --no-stream
   ```

5. **Contact support with:**
   - Container logs (`container-logs.txt`)
   - `.env` file (REDACT API keys!)
   - `docker-compose.yml` or `docker-stack.yml`
   - Error screenshots

---

## 10. Support & Contacts

### Technical Contacts

**Primary Contact:**
[Your Name]
Email: [Your Email]
Phone: [Your Phone] (for urgent issues)

**Backup Contact:**
[Backup Name/Team]
Email: [Backup Email]

### Resources

**Documentation:**
- Deployment Guide: This document
- User Guide: https://cinnamon.github.io/kotaemon/
- Developer Guide: https://cinnamon.github.io/kotaemon/development/
- Bitbucket Repository: https://bitbucket.org/moatdevelopers/moat-policy-chat-bot

**Upstream Project:**
- Original Project: https://github.com/Cinnamon/kotaemon
- Community Support: https://github.com/Cinnamon/kotaemon/discussions

### Escalation Path

1. **Level 1:** Application issues → Check this guide's troubleshooting section
2. **Level 2:** Infrastructure issues → Contact infrastructure team lead
3. **Level 3:** Urgent production issues → Contact primary technical contact above

### Change Management

All changes to production deployment must follow:
1. Test in development environment first
2. Document changes in GitHub
3. Schedule maintenance window (for major updates)
4. Notify stakeholders 24 hours in advance
5. Have rollback plan ready

---

## Appendix A: File Manifest

Complete list of files in deployment package:

```
deployment_package/
├── DEPLOYMENT_GUIDE.md          # This file
├── DEPLOYMENT_INSTRUCTIONS.md   # Quick start guide
├── HANDOFF_SUMMARY.md           # Executive summary
├── README.md                     # Project overview
├── CUSTOM_SETUP.md              # Customization notes
├── Dockerfile.optimized         # Production Dockerfile
├── docker-compose.yml           # Single-node deployment
├── docker-stack.yml             # HA deployment
├── .env.template                # Environment variables template
├── .dockerignore                # Build optimization
├── flowsettings.py              # Application configuration
├── app.py                       # Main entry point
├── sso_app.py                   # SSO entry point
├── sso_app_demo.py              # Demo entry point
├── launch.sh                    # Container entrypoint
├── libs/                        # Application libraries (entire directory)
│   ├── kotaemon/                # RAG framework
│   └── ktem/                    # Web UI
├── docs/                        # Documentation (entire directory)
└── scripts/                     # Helper scripts
    ├── download_pdfjs.sh
    └── deploy.ps1

Optional (if not using registry):
├── moat-chat-bot-latest.tar.gz  # Docker image archive (~1-2GB)
└── moat-chat-bot-latest.tar.gz.sha256  # Checksum
```

---

## Appendix B: Environment Variables Reference

Complete list of supported environment variables:

### Server Configuration
```bash
GRADIO_SERVER_NAME=0.0.0.0      # Bind address
GRADIO_SERVER_PORT=7860          # Port
GR_FILE_ROOT_PATH=/app           # File upload root
KH_APP_DATA_DIR=/app/ktem_app_data  # Data directory
```

### LLM Providers
```bash
# OpenAI
OPENAI_API_KEY=
OPENAI_API_BASE=https://api.openai.com/v1
OPENAI_CHAT_MODEL=gpt-4o-mini
OPENAI_EMBEDDINGS_MODEL=text-embedding-3-large

# Azure OpenAI
AZURE_OPENAI_ENDPOINT=
AZURE_OPENAI_API_KEY=
OPENAI_API_VERSION=2024-08-01-preview
AZURE_OPENAI_CHAT_DEPLOYMENT=
AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT=

# Cohere
COHERE_API_KEY=

# Mistral
MISTRAL_API_KEY=

# Voyage AI
VOYAGE_API_KEY=

# Local Models (Ollama)
LOCAL_MODEL=
LOCAL_MODEL_EMBEDDINGS=
KH_OLLAMA_URL=http://localhost:11434/v1/
```

### Advanced Features
```bash
# GraphRAG
GRAPHRAG_API_KEY=
GRAPHRAG_LLM_MODEL=gpt-4o-mini
GRAPHRAG_EMBEDDING_MODEL=text-embedding-3-small
USE_CUSTOMIZED_GRAPHRAG_SETTING=false
USE_LIGHTRAG=true

# Document Processing
AZURE_DI_ENDPOINT=
AZURE_DI_CREDENTIAL=
PDF_SERVICES_CLIENT_ID=
PDF_SERVICES_CLIENT_SECRET=

# PDF.js
PDFJS_VERSION_DIST=pdfjs-4.0.379-dist
```

### Authentication
```bash
# Mode selection
AUTHENTICATION_METHOD=          # Empty for Google, "KEYCLOAK" for Keycloak

# Google OAuth
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Keycloak
KEYCLOAK_SERVER_URL=
KEYCLOAK_CLIENT_ID=
KEYCLOAK_REALM=
KEYCLOAK_CLIENT_SECRET=

# Application modes
KH_DEMO_MODE=false              # Set true for demo mode (no auth)
KH_SSO_ENABLED=false            # Set true to enable SSO
KH_FEATURE_USER_MANAGEMENT=false  # Set true to enable user login
```

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-01-20 | Initial deployment guide | [Your Name] |

---

**End of Deployment Guide**
