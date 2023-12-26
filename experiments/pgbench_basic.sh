#!/bin/bash

# This script runs a basic pgbench test on a single node.

# Ensure the database is initialized for pgbench.
source pgbench.sh -T 1
sleep 1
./exe/background_hum.rb &

# This doesn't work because it exists when the script ends,
# so it has to be run manually.
# ./exe/pg_sammpler.rb
