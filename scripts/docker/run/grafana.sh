#!/bin/bash

CONTAINER_NAME="grafana"

if docker ps -a | grep -qw $CONTAINER_NAME; then
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME # not needed when container is removed with --rm
fi

# Some m4 magic to avoid committing token to repo while still
# having the convenience of the configuration file.
m4 -DINFLUXDB_TOKEN="$INFLUX_LOCAL_TOKEN" influxdb-datasource.m4 > influxdb-datasource.yml

docker buildx build -t grafana -f Dockerfile.grafana .
docker run -d --name grafana \
  -p 3000:3000 \
  -v grafana-storage:/var/lib/grafana \
  -v ./influxdb-datasource.yml:/etc/grafana/provisioning/datasources/influxdb-datasource.yml \
  grafana

