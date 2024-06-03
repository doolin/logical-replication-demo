#!/bin/bash

# Define the ClickHouse server URL
CLICKHOUSE_URL="http://localhost:8123"

# # Send a ping request to the ClickHouse server
# response=$(curl -s -o /dev/null -w "%{http_code}" $CLICKHOUSE_URL/ping)

# # Check the response code
# if [ "$response" -eq 200 ]; then
#   echo "ClickHouse server is up and running."
# else
#   echo "Failed to connect to ClickHouse server. HTTP status code: $response"
#   echo "Attempting to get more information..."
#   curl -v $CLICKHOUSE_URL/ping
# fi

# Check if the Docker container is running
# container_status=$(docker inspect -f '{{.State.Status}}' clickhouse_server)

# if [ "$container_status" != "running" ]; then
#   echo "ClickHouse Docker container is not running."
#   exit 1
# fi

# # Check ClickHouse server status inside the container
# echo "Checking ClickHouse server status inside the container..."
# docker exec clickhouse_server clickhouse-client --query "SELECT version()"

# # Send a ping request to the ClickHouse server
# response=$(curl -s -o /dev/null -w "%{http_code}" $CLICKHOUSE_URL/ping)

# # Check the response code
# if [ "$response" -eq 200 ]; then
#   echo "ClickHouse server is up and running."
# else
#   echo "Failed to connect to ClickHouse server. HTTP status code: $response"
#   echo "Attempting to get more information..."
#   curl -v $CLICKHOUSE_URL/ping
# fi


# # Define ClickHouse server URL and credentials
# CLICKHOUSE_URL="http://localhost:8123"
# CLICKHOUSE_USER="username"
# CLICKHOUSE_PASSWORD="password"

# # Encode username and password in Base64
# auth_token=$(echo -n "$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD" | base64)

# # Send a ping request to the ClickHouse server
# response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Basic $auth_token" $CLICKHOUSE_URL/ping)

# # Check the response code
# if [ "$response" -eq 200 ]; then
#   echo "ClickHouse server is up and running."
# else
#   echo "Failed to connect to ClickHouse server. HTTP status code: $response"
#   echo "Attempting to get more information..."
#   curl -v -H "Authorization: Basic $auth_token" $CLICKHOUSE_URL/ping
# fi


# Define ClickHouse server URL and credentials
CLICKHOUSE_URL="http://localhost:8123"
CLICKHOUSE_USER="username"
CLICKHOUSE_PASSWORD="password"

# Encode username and password in Base64
auth_token=$(echo -n "$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD" | base64)

# Function to run a query
run_query() {
  local query=$1
  curl -s -H "Authorization: Basic $auth_token" --data-binary "$query" $CLICKHOUSE_URL
}

# Send a ping request to the ClickHouse server
response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Basic $auth_token" $CLICKHOUSE_URL/ping)

# Check the response code
if [ "$response" -eq 200 ]; then
  echo "ClickHouse server is up and running."

  # Create a test table
  create_table_query="CREATE TABLE IF NOT EXISTS test_table (id UInt32, name String) ENGINE = MergeTree() ORDER BY id"
  run_query "$create_table_query"

  # Insert some data into the test table
  insert_data_query="INSERT INTO test_table VALUES (1, 'Alice'), (2, 'Bob'), (3, 'Charlie')"
  run_query "$insert_data_query"

  # Retrieve data from the test table
  select_query="SELECT * FROM test_table"
  echo "Retrieving data from test_table:"
  run_query "$select_query"
else
  echo "Failed to connect to ClickHouse server. HTTP status code: $response"
  echo "Attempting to get more information..."
  curl -v -H "Authorization: Basic $auth_token" $CLICKHOUSE_URL/ping
fi

