#!/bin/bash

CONTAINER_NAME="pubmetrics"

if docker ps -a | grep -qw $CONTAINER_NAME; then
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME # not needed when container is removed with --rm
fi

# InfluxDB
docker buildx build -t pubmetrics -f Dockerfile.influxdb .
docker run -d --name pubmetrics \
  -p 8086:8086 \
  -v influxdb-storage:/var/lib/influxdb2 \
  pubmetrics
