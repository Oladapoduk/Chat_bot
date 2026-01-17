
# Deploy Script for Moat-Chat Bot on Docker Swarm

$ErrorActionPreference = "Stop"
$StackName = "moat"
$ServiceName = "moat_moat-bot"

Write-Host "Checking Docker status..." -ForegroundColor Cyan
docker info > $null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker is not running. Please start Docker Desktop."
}

# 1. Initialize Swarm if not active
$swarmStatus = docker info --format '{{.Swarm.LocalNodeState}}'
if ($swarmStatus -eq "inactive") {
    Write-Host "Initializing Docker Swarm..." -ForegroundColor Yellow
    docker swarm init
} else {
    Write-Host "Docker Swarm is already active." -ForegroundColor Green
}

# 2. Build the image
Write-Host "Building Docker image (this may take a while)..." -ForegroundColor Cyan
docker build --target full -t moat-bot:latest .

# 3. Deploy the stack
Write-Host "Deploying stack '$StackName'..." -ForegroundColor Cyan
# Load env vars from .env if present (simple emulation)
if (Test-Path .env) {
    Write-Host "Loading .env file..."
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }
}

docker stack deploy -c docker-stack.yml $StackName

Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "Monitor status with: docker service ps $ServiceName"
Write-Host "Access the app at: http://localhost:7860"
