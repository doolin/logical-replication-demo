#!/bin/bash

# Leaving this here as placeholder documentation in case
# we need to set up bidirectional replication.
# SELECT pg_replication_origin_pause('origin_name');

# This is for supporting schema change examples.
PGPASSWORD=foobar psql -c "ALTER SUBSCRIPTION sub1 DISABLE;" -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -c "ALTER SUBSCRIPTION sub2 DISABLE;" -U postgres -p 5434 -h localhost
