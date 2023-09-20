#!/bin/bash

esc=""
redf="${esc}[31m";
reset="${esc}[0m"

press_enter()
{
  read -p "${redf}Press [Enter]...${reset}"
}

press_enter

docker container prune
docker system prune

# exit 0

# This is a sort of nuclear option, and will more or less delete everything
# which isn't running.
docker system prune -af && \
    docker image prune -af && \
    docker system prune -af --volumes && \ # deletes build cache objects
    docker system df
