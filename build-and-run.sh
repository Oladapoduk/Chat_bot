#!/bin/bash

# Build and run custom Kotaemon with NanoGraphRAG and LightRAG
# Usage: ./build-and-run.sh [build|run|restart]

set -e

IMAGE_NAME="kotaemon-custom"
IMAGE_TAG="latest"
CONTAINER_NAME="kotaemon-app"

cd ~/kotaemon

case "${1:-restart}" in
    build)
        echo "Building custom Kotaemon image with NanoGraphRAG and LightRAG..."
        docker build -f Dockerfile.custom -t ${IMAGE_NAME}:${IMAGE_TAG} .
        echo "Build complete! Image: ${IMAGE_NAME}:${IMAGE_TAG}"
        echo "Run './build-and-run.sh run' to start the container"
        ;;

    run)
        echo "Starting Kotaemon container..."
        docker run \
            --name ${CONTAINER_NAME} \
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
            ${IMAGE_NAME}:${IMAGE_TAG}
        ;;

    restart)
        echo "Rebuilding and restarting Kotaemon..."

        # Stop existing container if running
        if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
            echo "Stopping existing container..."
            docker stop ${CONTAINER_NAME}
        fi

        # Remove stopped container if exists
        if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
            echo "Removing stopped container..."
            docker rm ${CONTAINER_NAME}
        fi

        # Build new image
        echo "Building custom Kotaemon image..."
        docker build -f Dockerfile.custom -t ${IMAGE_NAME}:${IMAGE_TAG} .

        # Run new container
        echo "Starting new container..."
        docker run \
            --name ${CONTAINER_NAME} \
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
            ${IMAGE_NAME}:${IMAGE_TAG}
        ;;

    stop)
        echo "Stopping Kotaemon container..."
        docker stop ${CONTAINER_NAME} || echo "Container not running"
        ;;

    *)
        echo "Usage: $0 {build|run|restart|stop}"
        echo ""
        echo "  build   - Build the custom Docker image only"
        echo "  run     - Run the container (must build first)"
        echo "  restart - Stop, rebuild, and restart everything (default)"
        echo "  stop    - Stop the running container"
        exit 1
        ;;
esac
