#!/bin/bash

# This sets up a PostgreSQL datasource in Grafana.

# Grafana details
GRAFANA_HOST="localhost"  # Replace with your Grafana host if different
GRAFANA_PORT="3000"      # Replace if your Grafana port is different
GRAFANA_API_KEY="$GRAFANA_API_TOKEN"  # Replace with your actual Grafana API key

# PostgreSQL details
POSTGRES_HOST="host.docker.internal"  # Docker host IP on macOS for Docker container
POSTGRES_PORT="5435"
POSTGRES_DATABASE="publisher"
POSTGRES_USER="postgres"
POSTGRES_PASSWORD="foobar"

# API request
curl -X POST "http://${GRAFANA_HOST}:${GRAFANA_PORT}/api/datasources" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
     -d '{
           "name": "PostgreSQL - test 1",
           "type": "postgres",
           "access": "proxy",
           "url": "'${POSTGRES_HOST}':'${POSTGRES_PORT}'",
           "user": "'"${POSTGRES_USER}"'",
           "secureJsonData": {
              "password": "'"${POSTGRES_PASSWORD}"'"
           },
           "database": "'"${POSTGRES_DATABASE}"'",
           "basicAuth": false,
           "isDefault": false,
           "jsonData": {
              "sslmode": "disable"
            }
         }'


