#!/bin/bash

# Define the Docker socket path
DOCKER_SOCKET_PATH="$HOME/.docker/run/docker.sock"
DOCKER_SOCKET_LINK="/var/run/docker.sock"

# Remove 'root' and 'daviddoolin' from the 'docker' group
echo "Removing 'root' and 'daviddoolin' from the 'docker' group..."
sudo dseditgroup -o edit -d root -t user docker
sudo dseditgroup -o edit -d daviddoolin -t user docker

# Restore group ownership of the Docker socket to 'daemon'
echo "Restoring group ownership of the Docker socket to 'daemon'..."
sudo chown :daemon $DOCKER_SOCKET_PATH

# Restore original permissions of the Docker socket
echo "Restoring original permissions for the Docker socket..."
sudo chmod 755 $DOCKER_SOCKET_PATH

# Output final socket permissions
echo "Docker socket permissions:"
ls -l $DOCKER_SOCKET_LINK

