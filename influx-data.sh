#!/bin/bash

# InfluxDB parameters
TOKEN="$(cat ~/.influxdbv2/token)"
ORG_ID="inventium"
BUCKET="testem"
INFLUX_URL="http://localhost:8086"

# Number of data points
n=100

# Start time (in nanoseconds since the epoch)
# linux
# start_time=$(date +%s%N -d 'now - 1000 hour')
# macos, too fancy, make it simpler later.
start_time=$(date -jf "%Y-%m-%d %H:%M:%S" "$(date -v-100H "+%Y-%m-%d %H:%M:%S")" +%s)000000000

# Increment (1 hour in nanoseconds)
increment=$((1 * 3600 * 1000000000))

# Generate and post random data
for (( i=0; i<n; i++ ))
do
  # Calculate timestamp for data point
  timestamp=$((start_time + i * increment))

  # Generate random temperature between 20 and 30
  temperature=$((RANDOM % 11 + 20))

  # Generate data in InfluxDB line protocol format
  data="temperature,sensor=sensor1 value=$temperature $timestamp"

  # Post data using curl
  curl -s -XPOST "${INFLUX_URL}/api/v2/write?org=${ORG_ID}&bucket=${BUCKET}" \
        -H "Authorization: Token ${TOKEN}" \
        -H "Content-Type: text/plain" \
        --data-binary "${data}"
  
  echo "temperature,sensor=sensor1 value=$temperature $timestamp"

  sleep 0.2    
done
