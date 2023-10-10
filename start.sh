#!/bin/bash

source ./helper.sh
# TODO: add infotext to the helper script
# press_enter

# TODO: prompt the user to stop the containers first, then run cleanup.sh
# Run ./cleanup.sh first

docker buildx build . -t posttag
docker run --name posttag --rm -p 5433:5432 -e POSTGRES_PASSWORD=foobar -d posttag