#!/bin/bash

CONTAINER_NAME="traefik"

if docker ps -a | grep -qw $CONTAINER_NAME; then
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME # not needed when container is removed with --rm
fi


# docker run -d \
#   --name=traefik \
#   --network=web \
#   -p 80:80 \
#   -p 443:443 \
#   -p 8080:8080 \
#   -v /var/run/docker.sock:/var/run/docker.sock \
#   -v $(pwd)/traefik.yml:/etc/traefik/traefik.yml \
#   -v $(pwd)/certs:/certs \
#   traefik:v2.3

docker buildx build -t traefik -f Dockerfile.traefik .
docker run -d \
  --name=traefik \
  -p 80:80 \
  -p 443:443 \
  -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)"/traefik.yml:/etc/traefik/traefik.yml \
  -v "$(pwd)"/certs:/certs \
  traefik:v2.3
