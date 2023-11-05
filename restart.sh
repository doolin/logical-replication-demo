#!/bin/bash

source ./ansi_colors.sh
source ./helpers.sh
infotext "Build and restart the subscriber containers..."

IMAGE_NAME="pubsub"
DOCKERFILE_PATH="."
CONFIG_FILE_PATH="."
CONTAINERS=("subscriber1" "subscriber2" "publisher" "pubmetrics" "grafana")

for CONTAINER_NAME in "${CONTAINERS[@]}"; do
  if docker ps -a | grep -qw $CONTAINER_NAME; then
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME # not needed when container is removed with --rm
  fi
done

# Locally defined Docker file.
docker buildx build . -t $IMAGE_NAME # -f $DOCKERFILE_PATH .
docker run -d --name subscriber1 -m 512m --memory-swap 512m -p 5433:5432 -e POSTGRES_PASSWORD=foobar $IMAGE_NAME
docker run -d --name subscriber2 -m 512m --memory-swap 512m -p 5434:5432 -e POSTGRES_PASSWORD=foobar $IMAGE_NAME
docker run -d --name publisher -m 512m --memory-swap 512m -p 5435:5432 -e POSTGRES_PASSWORD=foobar $IMAGE_NAME

# Pull from Docker Hub.
docker buildx build -t pubmetrics -f Dockerfile.influxdb .
docker run -d --name pubmetrics -p 8086:8086 -v myInfluxVolume:/var/lib/influxdb2 pubmetrics
docker buildx build -t grafana -f Dockerfile.grafana .
docker run -d -p 3000:3000 --name grafana -v grafana-storage:/var/lib/grafana grafana

# TODO: metrics to put into influx
# 1. docker stats from publisher, subscriber1, subscriber2
# 2. database stats for publisher, subscriber1, subscriber2
# Connect the InfluxDB container to the pubsub_network
docker network ls | grep -q "pubsub_network" || docker network create pubsub_network
docker network connect pubsub_network pubmetrics
docker network connect pubsub_network grafana

# Optional: Remove old Docker images to free up space
# docker system prune -a

echo "Containers ${CONTAINERS[@]} have been updated."
