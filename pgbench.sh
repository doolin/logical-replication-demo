#!/bin/bash

# Initialize the database
# -s is scale factor
# -i is initialize
PGPASSWORD=foobar pgbench -h localhost -p 5435 -U postgres -i -s 10 publisher

# Run the benchmark
PGPASSWORD=foobar pgbench -h localhost -p 5435 -U postgres -T 600 -c 10 -j 2 publisher

