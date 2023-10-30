#!/bin/bash

source ./ansi_colors.sh
source ./helpers.sh
infotext "This will stop and remove the subscriber docker containers"
press_enter

containers=("subscriber1" "subscriber2")
for container in "${containers[@]}"; do
  docker stop "$container" >/dev/null 2>&1 # stdout and stderr to /dev/null
done

# The nuclear option, deletes all containers and images
# which aren't running.
infotext "Do you want to nuke ALL docker containers and images?"
read nukem
if [[ $nukem == "yes" ]]; then
  docker system prune -af && \
      docker image prune -af && \
      docker system prune -af --volumes && \ # deletes build cache objects
      docker system df # shows disk usage
else
  infotext "Not nuking docker containers and images."
fi