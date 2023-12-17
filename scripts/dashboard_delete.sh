#!/bin/bash

# Check if the correct number of arguments was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <dashboard_uid>"
    exit 1
fi

# Assign arguments to variables
GRAFANA_HOST="localhost:3000"
DASHBOARD_UID=$1

# API URL for deleting the dashboard
API_URL="http://${GRAFANA_HOST}/api/dashboards/uid/${DASHBOARD_UID}"

# Make the API request to delete the dashboard
response=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${API_URL}" \
     -H "Authorization: Bearer ${GRAFANA_API_TOKEN}" \
     -H "Content-Type: application/json")

# Check the response
if [ "$response" -eq 200 ]; then
    echo "Dashboard with UID ${DASHBOARD_UID} deleted successfully."
else
    echo "Failed to delete dashboard. HTTP response code: ${response}."
fi

