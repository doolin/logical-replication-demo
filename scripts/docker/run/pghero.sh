#!/bin/bash

docker buildx build -t pghero -f Dockerfile.pghero .

# docker run -ti -e DATABASE_URL=postgres://postgres:foobar@host.docker.internal:5435/publisher -p 9080:8080 pghero
docker run -d \
  --name pghero \
  -e DATABASE_URL=postgres://postgres:foobar@host.docker.internal:5435/publisher \
  -p 8080:8080 pghero