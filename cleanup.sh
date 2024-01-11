#!/bin/bash

# shellcheck disable=SC1091
source ./ansi_colors.sh
source ./helpers.sh
infotext "This will stop and remove the subscriber docker containers"
press_enter

containers=("subscriber1" "subscriber2" "publisher" "pubmetrics" "grafana" "telegraf" "fluentbit" "pghero")
for container in "${containers[@]}"; do
  docker stop "$container" >/dev/null 2>&1 # stdout and stderr to /dev/null
  docker rm "$container" >/dev/null 2>&1
done

# The nuclear option, deletes all containers and images
# which aren't running.
infotext "Do you want to nuke ALL docker containers and images?"
read -r nukem
if [[ $nukem == "yes" ]]; then
  docker system prune -af && \
      docker image prune -af && \
      docker system df # shows disk usage
else
  infotext "Not nuking docker containers and images."
fi

# Change this to remove local volumes only.
# if [[ $nukem == "yes" ]]; then
#   docker system prune -af && \
#       docker image prune -af && \
#       docker system prune -af --volumes && # This nukes all volummes including some I'd like to keep such as jupyter.
#       docker system df # shows disk usage
# else
#   infotext "Not nuking docker containers and images."
# fi
