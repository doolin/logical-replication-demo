#!/bin/bash

# TODO: warn the user that this will delete everything which isn't running.
# TODO: inform user this script will halt then delete the subscriber containers.
source ./ansi_colors.sh
source ./helpers.sh
infotext "This will clean up the example docker containers"
press_enter

containers=("subscriber1" "subscriber2")
for container in "${containers[@]}"; do
  docker stop "$container" >/dev/null 2>&1 # stdout and stderr to /dev/null
done

# docker container prune
# docker system prune

# This is a sort of nuclear option, and will more or less delete everything
# which isn't running.
infotext "Do you want to nuke all docker containers and images?"
read nukem
if [[ $nukem == "yes" ]]; then
  docker system prune -af && \
      docker image prune -af && \
      docker system prune -af --volumes && \ # deletes build cache objects
      docker system df # shows disk usage
else
  infotext "Not nuking docker containers and images."
fi