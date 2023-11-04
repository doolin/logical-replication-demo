#!/bin/bash

# Standalone script to drop subscribers and publishers.
PGPASSWORD=foobar psql -c "DROP SUBSCRIPTION IF EXISTS sub1;" -U postgres -p 5433 -h localhost 
PGPASSWORD=foobar psql -c "DROP SUBSCRIPTION IF EXISTS sub2;" -U postgres -p 5434 -h localhost
PGPASSWORD=foobar psql -c "DROP PUBLICATION IF EXISTS leadership_pub;" -U postgres -p 5435 -h localhost -d publisher
PGPASSWORD=foobar psql -c "DROP PUBLICATION IF EXISTS technical_pub;" -U postgres -p 5435 -h localhost -d publisher
