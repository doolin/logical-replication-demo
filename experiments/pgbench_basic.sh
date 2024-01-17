#!/bin/bash

# This script runs a basic pgbench test on a single node.

# Ensure the database is initialized for pgbench.
# This functionality should now be part of the Ruby script.
# source pgbench.sh -T 1
# sleep 1

DURATION=60
./exe/background_hum.rb -T $DURATION &
nohup ./exe/pg_sampler.rb -T $DURATION &
