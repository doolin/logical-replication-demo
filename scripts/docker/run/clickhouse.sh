#!/bin/bash

# Define variables
CONTAINER_NAME="clickhouse_server"
# NETWORK_NAME="pubsub_network"
# DOCKERFILE_PATH="./Dockerfile.clickhouse"

if docker ps -a | grep -qw $CONTAINER_NAME; then
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME # not needed when container is removed with --rm
fi

# Create the Docker network if it doesn't exist
# docker network inspect $NETWORK_NAME >/dev/null 2>&1 || \
# docker network create $NETWORK_NAME

# docker build -t clickhouse_custom -f $DOCKERFILE_PATH .
# docker run -d \
#     --name $CONTAINER_NAME \
#     --hostname $CONTAINER_NAME \
#     -e CLICKHOUSE_DB=my_database \
#     -e CLICKHOUSE_USER=username \
#     -e CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1 \
#     -e CLICKHOUSE_PASSWORD=password \
#     -p 8123:8123 \
#     -p 9000:9000 \
#     -p 9009:9009 \
#     clickhouse_custom


# docker run -d \
#     --name $CONTAINER_NAME \
#     --network $NETWORK_NAME \
#     --hostname $CONTAINER_NAME \
#     --restart unless-stopped \
#     --ulimit nofile=262144:262144 \
#     -p 8123:8123 \
#     -p 9000:9000 \
#     -p 9009:9009 \
#     clickhouse_custom


# https://hub.docker.com/r/clickhouse/clickhouse-server/
docker run -d \
    --name $CONTAINER_NAME \
    --hostname clickit \
    -e CLICKHOUSE_DB=my_database \
    -e CLICKHOUSE_USER=username \
    -e CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1 \
    -e CLICKHOUSE_PASSWORD=password \
    -p 8123:8123 \
    -p 9000:9000/tcp \
    clickhouse/clickhouse-server

#     # clickhouse_custom

# CONTAINER_NAME="clickhouse_server"
# if docker ps -a | grep -qw $CONTAINER_NAME; then
#   docker stop $CONTAINER_NAME
#   docker rm $CONTAINER_NAME # not needed when container is removed with --rm
# fi
# docker build -t clickhouse_custom -f Dockerfile.clickhouse .

# docker run -d \
#     --name $CONTAINER_NAME \
#     -e CLICKHOUSE_DB=my_database \
#     -e CLICKHOUSE_USER=username \
#     -e CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1 \
#     -e CLICKHOUSE_PASSWORD=password \
#     -p 8123:8123 \
#     -p 9000:9000/tcp \
#     clickhouse_custom
