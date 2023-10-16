#!/bin/bash

# TODO: see if the configuration can be done via psql instead of using
# the configuration file. In production, this will be necessary.

# TODO: create a sql script to add books with title, author, and topic.
# Have two topics: Leadership and Technology.
# 1. change table name from books to books.
# 2. add columns for author, title, and topic, with autoincrementing id.

# Replication commands for the localhost publisher database.
dropdb publisher
createdb publisher
# psql -c "CREATE TABLE books (id serial PRIMARY KEY, name varchar(20));" publisher
psql -c "CREATE TABLE books(a int, b text, PRIMARY KEY(a));" publisher
psql -c "INSERT INTO books VALUES (1, 'one'), (2, 'two'), (3, 'three');" publisher
psql -c "CREATE PUBLICATION bookspub FOR TABLE books;" publisher

# Replication commands for the Docker subscriber database.
# TODO: Run these commands from this script, they work in the console.
PGPASSWORD=foobar psql -c "CREATE TABLE books(a int, b text, PRIMARY KEY(a));" -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -c "CREATE SUBSCRIPTION sub1 CONNECTION 'host=host.docker.internal dbname=publisher' PUBLICATION bookspub;" -U postgres -p 5433 -h localhost

echo "All done"
