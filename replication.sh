#!/bin/bash

# Replication commands for the localhost publisher database.
dropdb foobar
createdb foobar
# psql -c "CREATE TABLE quux (id serial PRIMARY KEY, name varchar(20));" foobar
psql -c "CREATE TABLE quux(a int, b text, PRIMARY KEY(a));" foobar
psql -c "INSERT INTO quux VALUES (1, 'one'), (2, 'two'), (3, 'three');" foobar
psql -c "CREATE PUBLICATION quuxpub FOR TABLE quux;" foobar

# Replication commands for the Docker subscriber database.
# TODO: Wrap these statements in the appropriate psql commands.
# CREATE TABLE quux(a int, b text, PRIMARY KEY(a));
# CREATE SUBSCRIPTION sub1 CONNECTION 'host=host.docker.internal dbname=foobar' PUBLICATION quuxpub;

echo "All done"