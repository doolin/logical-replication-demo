#!/bin/bash

source ./ansi_colors.sh
source ./helpers.sh
infotext "Build and restart the subscriber containers..."

IMAGE_NAME="pubsub"
DOCKERFILE_PATH="."
CONFIG_FILE_PATH="."
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

# Locally defined Docker file.
docker buildx build . -t $IMAGE_NAME # -f $DOCKERFILE_PATH .
docker run -d --name subscriber1 -m $MEMORY --memory-swap $MEMORY -p 5433:5432 -e POSTGRES_PASSWORD=foobar $IMAGE_NAME
docker run -d --name subscriber2 -m $MEMORY --memory-swap $MEMORY -p 5434:5432 -e POSTGRES_PASSWORD=foobar $IMAGE_NAME
docker run -d --name publisher   -m $MEMORY --memory-swap $MEMORY -p 5435:5432 -e POSTGRES_PASSWORD=foobar $IMAGE_NAME


# InfluxDB
# TODO: change the volume name to influxdb-storage
docker buildx build -t pubmetrics -f Dockerfile.influxdb .
docker run -d --name pubmetrics -p 8086:8086 -v myInfluxVolume:/var/lib/influxdb2 pubmetrics


# Grafana
m4 -DINFLUXDB_TOKEN=$INFLUX_LOCAL_TOKEN influxdb-datasource.m4 > influxdb-datasource.yml
docker buildx build -t grafana -f Dockerfile.grafana .
docker run -d --name grafana \
  -p 3000:3000 \
  -v grafana-storage:/var/lib/grafana \
  -v ./influxdb-datasource.yml:/etc/grafana/provisioning/datasources/influxdb-datasource.yml \
  grafana
# rm influxdb-datasource.yml


# Telegraf
# TODO: display docker stats in influx
localconf="/$HOME/src/logical-replication-demo/telegraf.conf"
docker buildx build -t telegraf -f Dockerfile.telegraf .
# Apparently, the network needs to be created before the container is run.
docker network ls | grep -q "pubsub_network" || docker network create pubsub_network
# TODO: constrain memory.
docker run -d --name telegraf \
  -e INFLUX_LOCAL_TOKEN=$INFLUX_LOCAL_TOKEN \
  -e INFLUX_LOCAL_ORG=$INFLUX_LOCAL_ORG \
  -e INFLUX_LOCAL_BUCKET=$INFLUX_LOCAL_BUCKET \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $localconf:/etc/telegraf/telegraf.conf:ro \
  --net=pubsub_network telegraf


# TODO: pull fluentbit image and run it
# https://fluentbit.io/how-it-works/
# docker buildx build -t fluentbit -f Dockerfile.fluentbit .
# docker run -d --name fluentbit -p 24224:24224 -p 24224:24224/udp -v fluentbit-storage:/fluent-bit/etc fluentbit


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


# TODO: hook parameterization.
# DEFAULT_MEMORY="512m"
# MEMORY=$DEFAULT_MEMORY

# # Function to show help
# show_help() {
#     echo "Usage: $0 [options]"
#     echo "Options:"
#     echo "  -m <memory>    Set the memory limit for Docker (e.g., 256m, 1g)"
#     echo "  -h             Display this help and exit"
# }

# # Process command-line options
# while getopts ":hm:" opt; do
#     case ${opt} in
#         h )
#             show_help
#             exit 0
#             ;;
#         m )
#             MEMORY="${OPTARG}"
#             # Check if the provided memory ends with a letter (b, k, m, g)
#             if [[ ! "$MEMORY" =~ [a-zA-Z]$ ]]; then
#                 MEMORY="${MEMORY}m"
#             fi
#             ;;
#         \? )
#             echo "Invalid option: -$OPTARG" >&2
#             show_help
#             exit 1
#             ;;
#         : )
#             echo "Option -$OPTARG requires an argument." >&2
#             exit 1
#             ;;
#     esac
# done

# echo "Memory allocated for Docker: $MEMORY"

# # Example usage in a Docker command
# # docker run -m $MEMORY your_docker_image
