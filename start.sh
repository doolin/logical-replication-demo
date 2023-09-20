#!/bin/bash

esc=""
redf="${esc}[31m";
reset="${esc}[0m"

press_enter()
{
  read -p "${redf}Press [Enter]...${reset}"
}

press_enter

# Run ./cleanup.sh first

docker buildx build . -t posttag
docker run --name posttag --rm -p 5433:5432 -e POSTGRES_PASSWORD=foobar -d posttag