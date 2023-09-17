#!/bin/bash

esc=""
redf="${esc}[31m";
reset="${esc}[0m"

press_enter()
{
  read -p "${redf}Press [Enter]...${reset}"
}

press_enter

# Run cleanup.sh for these commands:
# docker container prune
# docker system prune

docker buildx build . -t posttag
docker run --name posttag -p 5433:5432 -e POSTGRES_PASSWORD=foobar -d posttag
