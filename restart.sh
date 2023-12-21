#!/bin/bash

# TODO: metrics to put into influx
# 1. docker stats from publisher, subscriber1, subscriber2
# 2. database stats for publisher, subscriber1, subscriber2

source ./ansi_colors.sh
source ./helpers.sh
infotext "Build and restart the subscriber containers..."

CONTAINERS=("subscriber1" "subscriber2" "publisher" "pubmetrics" "grafana" "telegraf")

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
source ./scripts/postgres_run.sh

# InfluxDB
source ./scripts/influx_run.sh

# Grafana
source ./scripts/grafana_run.sh

# Telegraf from Dockerfile.telegraf
source ./scripts/telegraph_run.sh

# Connect the InfluxDB container to the pubsub_network
docker network ls | grep -q "pubsub_network" || docker network create pubsub_network
docker network connect pubsub_network pubmetrics
docker network connect pubsub_network grafana

# Optional: Remove old Docker images to free up space
# docker system prune -a

echo "Containers have been updated."
