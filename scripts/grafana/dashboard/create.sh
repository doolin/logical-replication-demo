
#!/bin/bash

# Grafana API details
GRAFANA_HOST="http://localhost:3000"
GRAFANA_API_TOKEN=$GRAFANA_API_TOKEN

# Dashboard JSON file
# DASHBOARD_JSON="./scripts/grafana/json/dashboard.json"
# DASHBOARD_JSON="./scripts/grafana/json/flux_query.json"
DASHBOARD_JSON="./scripts/grafana/json/four_panel.json"

# Check if the dashboard JSON file exists
if [ ! -f "$DASHBOARD_JSON" ]; then
    echo "Dashboard JSON file not found: $DASHBOARD_JSON"
    exit 1
fi


# API URL for dashboard creation
API_URL="$GRAFANA_HOST/api/dashboards/db"

# Make the API request to create the dashboard
curl -X POST "$API_URL" \
     -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
     -H "Content-Type: application/json" \
     -d @"$DASHBOARD_JSON"

# Check if the dashboard was created successfully
if [ $? -eq 0 ]; then
    echo "Dashboard created successfully."
else
    echo "Failed to create dashboard."
fi
