#!/bin/bash

IMAGE_NAME="subscriber"
DOCKERFILE_PATH="."
CONFIG_FILE_PATH="."
CONTAINERS=("subscriber1" "subscriber2")

for CONTAINER_NAME in "${CONTAINERS[@]}"; do
  if docker ps -a | grep -qw $CONTAINER_NAME; then
    docker stop $CONTAINER_NAME
    # docker rm $CONTAINER_NAME # not needed when container is removed with --rm
  fi
done

docker buildx build . -t $IMAGE_NAME # -f $DOCKERFILE_PATH .
docker run --name subscriber1 --rm -p 5433:5432 -e POSTGRES_PASSWORD=foobar -d subscriber
docker run --name subscriber2 --rm -p 5434:5432 -e POSTGRES_PASSWORD=foobar -d subscriber

# Optional: Remove old Docker images to free up space
# docker system prune -a

echo "Containers ${CONTAINERS[@]} have been updated."
