#!/bin/bash

# Check if the correct number of arguments was provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <grafana_host> <dashboard_name> <api_key>"
    exit 1
fi

# Assign arguments to variables
GRAFANA_HOST=$1
DASHBOARD_NAME=$2
API_KEY=$3

# Step 1: Retrieve the dashboard UID by its name
SEARCH_API_URL="http://${GRAFANA_HOST}/api/search?query=${DASHBOARD_NAME}"
DASHBOARD_UID=$(curl -s -H "Authorization: Bearer ${API_KEY}" "${SEARCH_API_URL}" | jq -r '.[] | select(.title=="'"${DASHBOARD_NAME}"'") | .uid')

# Check if a UID was found
if [ -z "$DASHBOARD_UID" ]; then
    echo "No dashboard found with name: ${DASHBOARD_NAME}"
    exit 1
fi

# Step 2: Delete the dashboard using the UID
DELETE_API_URL="http://${GRAFANA_HOST}/api/dashboards/uid/${DASHBOARD_UID}"
response=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${DELETE_API_URL}" \
     -H "Authorization: Bearer ${API_KEY}" \
     -H "Content-Type: application/json")

# Check the response
if [ "$response" -eq 200 ]; then
    echo "Dashboard '${DASHBOARD_NAME}' deleted successfully."
else
    echo "Failed to delete dashboard. HTTP response code: ${response}."
fi

