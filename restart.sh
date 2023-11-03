#!/bin/bash

IMAGE_NAME="pubsub"
DOCKERFILE_PATH="."
CONFIG_FILE_PATH="."
CONTAINERS=("subscriber1" "subscriber2" "publisher" "pubmetrics")

for CONTAINER_NAME in "${CONTAINERS[@]}"; do
  if docker ps -a | grep -qw $CONTAINER_NAME; then
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME # not needed when container is removed with --rm
  fi
done

# Locally defined Docker file.
docker buildx build . -t $IMAGE_NAME # -f $DOCKERFILE_PATH .
docker run -d --name subscriber1 -p 5433:5432 -e POSTGRES_PASSWORD=foobar $IMAGE_NAME
docker run -d --name subscriber2 -p 5434:5432 -e POSTGRES_PASSWORD=foobar $IMAGE_NAME
docker run -d --name publisher -p 5435:5432 -e POSTGRES_PASSWORD=foobar $IMAGE_NAME

# Pull from Docker Hub.
docker buildx build -t pubmetrics -f Dockerfile.influxdb .
docker run -d --name pubmetrics -p 8086:8086 -v myInfluxVolume:/var/lib/influxdb2 pubmetrics


# Optional: Remove old Docker images to free up space
# docker system prune -a

echo "Containers ${CONTAINERS[@]} have been updated."
