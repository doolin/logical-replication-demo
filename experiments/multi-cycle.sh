#!/bin/bash

# Attempt to break the system by running a bunch of processes at once.
# It didn't really work.

DURATION=600
nohup ./exe/background_hum.rb -T $DURATION &
nohup ./exe/pulser.rb -T $DURATION -f 0.1 &
sleep 1
nohup ./exe/pulser.rb -T $DURATION -f 0.05 &
sleep 3
nohup ./exe/pulser.rb -c 50 -T $DURATION -f 0.10 &
nohup ./exe/pg_sampler.rb -T $DURATION &
