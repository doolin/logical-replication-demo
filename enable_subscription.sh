#!/bin/bash

# This is for supporting schema change examples.
PGPASSWORD=foobar psql -c "ALTER SUBSCRIPTION sub1 ENABLE;" -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -c "ALTER SUBSCRIPTION sub2 ENABLE;" -U postgres -p 5434 -h localhost
