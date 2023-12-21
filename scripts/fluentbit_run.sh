#!/bin/bash

CONTAINER_NAME="fluentbit"

if docker ps -a | grep -qw $CONTAINER_NAME; then
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME # not needed when container is removed with --rm
fi

# TODO: pull fluentbit image and run it
# https://fluentbit.io/how-it-works/
# docker buildx build -t fluentbit -f Dockerfile.fluentbit .
# docker run -d --name fluentbit -p 24224:24224 -p 24224:24224/udp -v fluentbit-storage:/fluent-bit/etc fluentbit

