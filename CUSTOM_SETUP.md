# Kotaemon Custom Setup - Moat Homes

This document describes the custom setup for Kotaemon deployment at Moat Homes.

## Customizations Applied

### 1. Login Page Disabled
- **File Modified**: `flowsettings.py` (line 75)
- **Change**: Set `KH_FEATURE_USER_MANAGEMENT = False`
- **Result**: Users land directly in the application without authentication

### 2. LLMs and Embeddings Tabs Hidden
- **File Modified**: `libs/ktem/ktem/pages/resources/__init__.py` (lines 22, 25)
- **Change**: Added `visible=False` to both LLMs and Embeddings tabs
- **Result**: API keys are protected from public users who can only see:
  - Index Collections
  - Rerankings

### 3. NanoGraphRAG and LightRAG Installed
- **Files Created**:
  - `Dockerfile.custom` - Custom Docker image with both GraphRAG implementations
  - `build-and-run.sh` - Convenience script for building and running
- **Result**: Advanced graph-based retrieval capabilities enabled

## Quick Start

### Build and Run (First Time)

```bash
cd ~/kotaemon
./build-and-run.sh
```

This will:
1. Build a custom Docker image with NanoGraphRAG and LightRAG
2. Start the container with all customizations applied
3. Make the application available at http://35.242.165.245:7860

### Subsequent Runs

**To restart after code changes:**
```bash
cd ~/kotaemon
./build-and-run.sh restart
```

**To stop the container:**
```bash
cd ~/kotaemon
./build-and-run.sh stop
```

**To only build (without running):**
```bash
cd ~/kotaemon
./build-and-run.sh build
```

**To run existing image:**
```bash
cd ~/kotaemon
./build-and-run.sh run
```

## Manual Docker Commands

If you prefer to run Docker commands manually:

### Build Custom Image
```bash
cd ~/kotaemon
docker build -f Dockerfile.custom -t kotaemon-custom:latest .
```

### Run Container
```bash
cd ~/kotaemon
docker run \
  --name kotaemon-app \
  -e GRADIO_SERVER_NAME=0.0.0.0 \
  -e GRADIO_SERVER_PORT=7860 \
  -e USE_NANO_GRAPHRAG=true \
  -e USE_LIGHTRAG=true \
  -v ./ktem_app_data:/app/ktem_app_data \
  -v ./flowsettings.py:/app/flowsettings.py \
  -v ./libs/ktem:/app/libs/ktem \
  -v ./libs/kotaemon:/app/libs/kotaemon \
  -p 7860:7860 \
  -it --rm \
  kotaemon-custom:latest
```

### Stop Container
```bash
docker stop kotaemon-app
```

## Using GraphRAG Features

Once the application is running with NanoGraphRAG and LightRAG installed:

1. Navigate to the **Resources** tab
2. Go to **Index Collections**
3. When creating a new collection, you'll see these options:
   - **File Collection** - Standard retrieval
   - **NanoGraphRAG Collection** - Graph-based retrieval using NanoGraphRAG
   - **LightRAG Collection** - Graph-based retrieval using LightRAG

4. Set your default LLM and Embedding models in the Resources settings (Note: LLMs and Embeddings tabs are hidden for regular users, but admins can access them via direct configuration)

## Environment Variables

The following environment variables control GraphRAG features:

- `USE_NANO_GRAPHRAG=true` - Enable NanoGraphRAG
- `USE_LIGHTRAG=true` - Enable LightRAG
- `USE_MS_GRAPHRAG=true` - Enable Microsoft GraphRAG (default)

These are set in the `build-and-run.sh` script and `Dockerfile.custom`.

## File Structure

```
~/kotaemon/
├── Dockerfile.custom          # Custom Dockerfile with GraphRAG support
├── build-and-run.sh          # Convenience script for building and running
├── flowsettings.py           # Main configuration (login disabled)
├── libs/
│   ├── ktem/
│   │   └── ktem/
│   │       └── pages/
│   │           └── resources/
│   │               └── __init__.py  # Resources tabs (LLMs/Embeddings hidden)
│   └── kotaemon/
├── ktem_app_data/            # Application data (persisted)
└── CUSTOM_SETUP.md          # This file

```

## Troubleshooting

### Version Conflicts with hnswlib

If you encounter version conflicts during build:
```bash
# This is already handled in Dockerfile.custom, but if needed manually:
pip uninstall hnswlib chroma-hnswlib
pip install chroma-hnswlib
```

### Container Won't Start

Check if port 7860 is already in use:
```bash
sudo lsof -i :7860
# Kill the process if needed
```

### Changes Not Reflecting

If your code changes aren't reflected:
1. Stop the container: `./build-and-run.sh stop`
2. Rebuild and restart: `./build-and-run.sh restart`

### Check Container Logs

```bash
docker logs kotaemon-app
```

## Important Notes

1. **Data Persistence**: The `ktem_app_data` directory is mounted as a volume, so your documents and indices persist across container restarts.

2. **Code Changes**: Changes to files in `libs/ktem` and `libs/kotaemon` are mounted as volumes, so they take effect immediately after restarting the container (no rebuild needed).

3. **Configuration Changes**: Changes to `flowsettings.py` also take effect on container restart.

4. **Dockerfile Changes**: If you modify `Dockerfile.custom`, you must rebuild the image using `./build-and-run.sh restart` or `./build-and-run.sh build`.

## Access Information

- **URL**: http://35.242.165.245:7860
- **Authentication**: Disabled (direct access)
- **API Keys**: Protected (LLMs/Embeddings tabs hidden)

## Support

For issues or questions:
- GitHub: https://github.com/Cinnamon/kotaemon
- Report issues: https://github.com/Cinnamon/kotaemon/issues
