#!/bin/bash

# The  intent of this script is to invoke a Ruby script that
# produces a cyclic load on the database. The script will be
# able to execute in the background, by itself, or in combination
# with other scripts.

# Ensure the database is initialized for pgbench.
source pgbench.sh -T 1
sleep 1
# ./exe/cyclic_load.rb &
