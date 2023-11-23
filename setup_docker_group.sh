#!/bin/bash

# Define the Docker socket path
DOCKER_SOCKET_PATH="$HOME/.docker/run/docker.sock"
DOCKER_SOCKET_LINK="/var/run/docker.sock"

# Create the 'docker' group
echo "Creating the 'docker' group..."
sudo dseditgroup -o create docker

# Add 'root' and 'daviddoolin' to the 'docker' group
echo "Adding 'root' and 'daviddoolin' to the 'docker' group..."
sudo dseditgroup -o edit -a root -t user docker
sudo dseditgroup -o edit -a daviddoolin -t user docker

# Change group ownership of the Docker socket
echo "Changing group ownership of the Docker socket..."
sudo chown :docker $DOCKER_SOCKET_PATH

# Change permissions of the Docker socket
echo "Setting permissions for the Docker socket..."
sudo chmod 660 $DOCKER_SOCKET_PATH

# Output final socket permissions
echo "Docker socket permissions:"
ls -l $DOCKER_SOCKET_LINK

