#!/bin/bash

# Define variables
CONTAINER_NAME="clickhouse_server"
NETWORK_NAME="pubsub_network"
DOCKERFILE_PATH="./Dockerfile.clickhouse"

if docker ps -a | grep -qw $CONTAINER_NAME; then
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME # not needed when container is removed with --rm
fi

# Create the Docker network if it doesn't exist
# docker network inspect $NETWORK_NAME >/dev/null 2>&1 || \
# docker network create $NETWORK_NAME

# Build the Docker image
docker build -t clickhouse_custom -f $DOCKERFILE_PATH .

# Run the Docker container with specific configurations
docker run -d \
    --name $CONTAINER_NAME \
    --network $NETWORK_NAME \
    --hostname $CONTAINER_NAME \
    --restart unless-stopped \
    --ulimit nofile=262144:262144 \
    -p 8123:8123 \
    -p 9000:9000 \
    -p 9009:9009 \
    clickhouse_custom
