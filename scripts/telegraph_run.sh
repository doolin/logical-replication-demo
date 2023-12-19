#!/bin/bash

CONTAINERS=("telegraf")

for CONTAINER_NAME in "${CONTAINERS[@]}"; do
  if docker ps -a | grep -qw $CONTAINER_NAME; then
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME # not needed when container is removed with --rm
  fi
done

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
