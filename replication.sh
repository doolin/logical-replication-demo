#!/bin/bash

# TODO: see if the configuration can be done via psql instead of using
# the configuration file. In production, this will be necessary.

# TODO: create a sql script to add books with title, author, and topic.
#       Have two topics: Leadership and Technology.
# 1. change table name from books to books.
# 2. add columns for author, title, and topic, with autoincrementing id.
# 3. determine how autoincrementing id works with replication.
# 4. create a sql or csv file for importing books. CSV is probably easier.
# 5. consider having the schema in its own SQL file, first step is extracting
#    schema to a bash string.

# Replication commands for the localhost publisher database.
dropdb publisher
createdb publisher
# TODO: move to a schema.sql file
schema="CREATE TABLE books(a int, b text, PRIMARY KEY(a));"

psql -c "$schema" publisher
psql -c "INSERT INTO books VALUES (1, 'one'), (2, 'two'), (3, 'three');" publisher
psql -c "CREATE PUBLICATION bookspub FOR TABLE books;" publisher

# Replication commands for the Docker subscriber database.
# TODO: Run these commands from this script, they work in the console.
# TODO: create a subscrider1 database in the subscriber1 container.
PGPASSWORD=foobar psql -c "$schema" -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -c "CREATE SUBSCRIPTION sub1 CONNECTION 'host=host.docker.internal dbname=publisher' PUBLICATION bookspub;" -U postgres -p 5433 -h localhost

# TODO: create a subscriber2

echo "All done"
