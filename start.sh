#!/bin/bash

# NOTE: This script is deprecated in favor of restart.sh
source ./scripts/utils/helpers.sh
infotext "Build and start the subscriber containers..."

docker buildx build . -t subscriber
docker run --name subscriber1 --rm -p 5433:5432 -e POSTGRES_PASSWORD=foobar -d subscriber
docker run --name subscriber2 --rm -p 5434:5432 -e POSTGRES_PASSWORD=foobar -d subscriber