#!/bin/bash

IMAGE_NAME="pubsub"
DOCKERFILE_PATH="."
CONFIG_FILE_PATH="."
CONTAINERS=("subscriber1" "subscriber2" "publisher")

for CONTAINER_NAME in "${CONTAINERS[@]}"; do
  if docker ps -a | grep -qw $CONTAINER_NAME; then
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME # not needed when container is removed with --rm
  fi
done

if [ "$1" ]; then
    MEMORY="${1}m"
else
    MEMORY="512m"
fi

# PostgresQL databases
docker buildx build . -t $IMAGE_NAME # -f $DOCKERFILE_PATH .
docker run -d --name subscriber1 -m $MEMORY --memory-swap $MEMORY -p 5433:5432 -e POSTGRES_PASSWORD=foobar $IMAGE_NAME
docker run -d --name subscriber2 -m $MEMORY --memory-swap $MEMORY -p 5434:5432 -e POSTGRES_PASSWORD=foobar $IMAGE_NAME
docker run -d --name publisher   -m $MEMORY --memory-swap $MEMORY -p 5435:5432 -e POSTGRES_PASSWORD=foobar $IMAGE_NAME

