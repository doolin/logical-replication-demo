#!/bin/bash

# TODO: see if the configuration can be done via psql instead of using
# the configuration file. In production, this will be necessary.
# - The settings can be changed at the psql prompt and will be preserved on a container restart,
#   given the container data is persisted. GPT asserts the data is persisted between stops and
#   starts of the container. It will be lost when the container is deleted.
# - The setting are stored in the `pg_settings` table.

# TODO: create a sql script to add books with title, author, and topic.
#       Have two topics: Leadership and Technology.
# 1. (DONE) change table name from quux to books.
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

# Publisher
# TODO: add a sequential id table, see profiles table in tasklets_development.
# Reminder: -c indicates a sql command to run.
psql -c "$schema" publisher
psql -c "INSERT INTO books VALUES (1, 'one'), (2, 'two'), (3, 'three');" publisher
psql -c "CREATE PUBLICATION bookspub FOR TABLE books;" publisher

# Test the goodreads schemas
psql -f ./goodreads_pub_schema.sql publisher

# Subscriber
# Replication commands for the Docker subscriber database.
# TODO: Run these commands from this script, they work in the console.
# TODO: create a subscrider1 database in the subscriber1 container.
# TODO: ensure there is no sequence table in the subscriber1 database.
PGPASSWORD=foobar psql -c "$schema" -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -c "CREATE SUBSCRIPTION sub1 CONNECTION 'host=host.docker.internal dbname=publisher' PUBLICATION bookspub;" -U postgres -p 5433 -h localhost

PGPASSWORD=foobar psql -U postgres -p 5433 -h localhost -f ./goodreads_pub_schema.sql


# TODO: create a subscriber2

echo "All done"
