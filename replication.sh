#!/bin/bash

# TODO: see if the configuration can be done via psql instead of using
# the configuration file. In production, this will be necessary.

# Replication commands for the localhost publisher database.
dropdb foobar
createdb foobar
# psql -c "CREATE TABLE quux (id serial PRIMARY KEY, name varchar(20));" foobar
psql -c "CREATE TABLE quux(a int, b text, PRIMARY KEY(a));" foobar
psql -c "INSERT INTO quux VALUES (1, 'one'), (2, 'two'), (3, 'three');" foobar
psql -c "CREATE PUBLICATION quuxpub FOR TABLE quux;" foobar

# Replication commands for the Docker subscriber database.
# TODO: Run these commands from this script, they work in the console.
PGPASSWORD=foobar psql -c "CREATE TABLE quux(a int, b text, PRIMARY KEY(a));" -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -c "CREATE SUBSCRIPTION sub1 CONNECTION 'host=host.docker.internal dbname=foobar' PUBLICATION quuxpub;" -U postgres -p 5433 -h localhost

echo "All done"