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

# Pull from Docker Hub.
docker buildx build -t pubmetrics -f Dockerfile.influxdb .
docker run -d --name pubmetrics -p 8086:8086 -v myInfluxVolume:/var/lib/influxdb2 pubmetrics
docker buildx build -t grafana -f Dockerfile.grafana .
docker run -d --name grafana -p 3000:3000 -v grafana-storage:/var/lib/grafana grafana
# TODO: pull fluentbit image and run it
# https://fluentbit.io/how-it-works/
# docker buildx build -t fluentbit -f Dockerfile.fluentbit .
# docker run -d --name fluentbit -p 24224:24224 -p 24224:24224/udp -v fluentbit-storage:/fluent-bit/etc fluentbit

# Pull logstash image and run it
# docker pull docker.elastic.co/logstash/logstash:7.9.2
# docker run -d --name logstash -p 5000:5000 -v logstash-storage:/usr/share/logstash/pipeline docker.elastic.co/logstash/logstash:7.9.2

# Pull elasticsearch image and run it
# docker pull docker.elastic.co/elasticsearch/elasticsearch:7.9.2
# docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.9.2

# Pull kibana image and run it
# docker pull docker.elastic.co/kibana/kibana:7.9.2
# docker run -d --name kibana -p 5601:5601 docker.elastic.co/kibana/kibana:7.9.2

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
