#!/bin/bash

# Grafana API details
GRAFANA_HOST="http://localhost:3000"
API_URL="$GRAFANA_HOST/api/dashboards/db"


# Dashboard JSON file
# TODO: Loop over these files using the output from `ls`.
# DASHBOARD_JSON="./scripts/grafana/json/flux_query.json"
# DASHBOARD_JSON="./scripts/grafana/json/container_metrics.json"
DASHBOARD_JSON="./scripts/grafana/json/postgres_stats.json"
# DASHBOARD_JSON="./scripts/grafana/json/postgres_metrics.json"

# This Bash script snippet defines DASHBOARD_JSON as an array
# containing three file paths. You can access the elements of
# this array using their index (starting from 0) like this:
# DASHBOARD_JSON[0], DASHBOARD_JSON[1], and so on.

# Check if the dashboard JSON file exists
if [ ! -f "$DASHBOARD_JSON" ]; then
    echo "Dashboard JSON file not found: $DASHBOARD_JSON"
    exit 1
fi

# Make the API request to create the dashboard
curl -X POST "$API_URL" \
     -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
     -H "Content-Type: application/json" \
     -d @"$DASHBOARD_JSON"

# Check if the dashboard was created successfully
# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
    echo "Dashboard created successfully."
else
    echo "Failed to create dashboard."
fi
