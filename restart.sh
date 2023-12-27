#!/bin/bash

# TODO: metrics to put into influx
# 1. docker stats from publisher, subscriber1, subscriber2
# 2. database stats for publisher, subscriber1, subscriber2

source ./ansi_colors.sh
source ./helpers.sh
infotext "Build and restart the subscriber containers..."

CONTAINERS=("subscriber1" "subscriber2" "publisher" "pubmetrics" "grafana" "telegraf" "fluentbit")

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

# PostgresQL
source ./scripts/docker/run/postgres.sh

# InfluxDB
source ./scripts/docker/run/influx.sh

# Grafana
source ./scripts/docker/run/grafana.sh

# This should be removed from the repo once the container is running.
# rm influxdb-datasource.yml

# Telegraf from Dockerfile.telegraf
source ./scripts/docker/run/telegraf.sh

# FluentBit builds and runs from this location.
# source ./scripts/docker/run/fluentbit.sh

# Connect the InfluxDB container to the pubsub_network
docker network ls | grep -q "pubsub_network" || docker network create pubsub_network
docker network connect pubsub_network pubmetrics
docker network connect pubsub_network grafana

# Optional: Remove old Docker images to free up space
# docker system prune -a

# Automatically construct metrics dashboard
source ./scripts/grafana/dashboard/create.sh


echo "Containers have been updated."
