#!/bin/bash

source ./ansi_colors.sh
source ./helpers.sh
infotext "Build and start the subscriber containers..."
# press_enter

# TODO: prompt the user to stop the containers first, then run cleanup.sh
# Run ./cleanup.sh first

docker buildx build . -t subscriber
docker run --name subscriber1 --rm -p 5433:5432 -e POSTGRES_PASSWORD=foobar -d subscriber
docker run --name subscriber2 --rm -p 5434:5432 -e POSTGRES_PASSWORD=foobar -d subscriber