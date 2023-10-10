#!/bin/bash

# TODO: warn the user that this will delete everything which isn't running.
# TODO: ask the user to stop the containers first.
# TODO: set this up to only operate on the `posttag` container.

source ./helper.sh
press_enter

# docker container prune
# docker system prune

# This is a sort of nuclear option, and will more or less delete everything
# which isn't running.
docker system prune -af && \
    docker image prune -af && \
    docker system prune -af --volumes && \ # deletes build cache objects
    docker system df
