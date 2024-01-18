#!/bin/bash

# The  intent of this script is to invoke a Ruby script that
# produces a cyclic load on the database. The script will be
# able to execute in the background, by itself, or in combination
# with other scripts.

# Ensure the database is initialized for pgbench.
# source pgbench.sh -T 1
# sleep 1

DURATION=300
nohup ./exe/background_hum.rb -T $DURATION &
nohup ./exe/pulser.rb -T $DURATION -f 0.1 &
sleep 1
nohup ./exe/pulser.rb -T $DURATION -f 0.05 &
nohup ./exe/pg_sampler.rb -T $DURATION &
