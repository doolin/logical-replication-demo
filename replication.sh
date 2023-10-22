#!/bin/bash

# TODO: see if the configuration can be done via psql instead of using
# the configuration file. In production, this will be necessary.
# - The settings can be changed at the psql prompt and will be preserved on a container restart,
#   given the container data is persisted. GPT asserts the data is persisted between stops and
#   starts of the container. It will be lost when the container is deleted.
# - The settings are stored in the `pg_settings` table.

# TODO: create a sql script to add books with title, author, and topic.
#       Have two topics: Leadership and Technology.
# 1. add columns for author, title, and topic, with autoincrementing id.
# 2. create a sql or csv file for importing books. CSV is probably easier.
# 3. create a publication for the books table splitting replication by topic

# TODO: due diligence on https://github.com/shayonj/pg_easy_replicate
# TODO: due diliegnce on pglogical

# Replication commands for the localhost publisher database.
dropdb publisher
createdb publisher

# Publisher
# Reminder: -f loads a file, -c indicates a sql command to run.
psql -f books_schema.sql publisher
psql -c "CREATE SEQUENCE books_id_seq ;" publisher
psql -c "ALTER TABLE books ALTER COLUMN id SET DEFAULT nextval('books_id_seq');" publisher

psql -c "\COPY books ("sku", "title", "topic") FROM './books_data.csv' DELIMITER ',' CSV HEADER;" publisher
psql -c "CREATE PUBLICATION bookspub FOR TABLE books;" publisher

psql -f ./goodreads_pub_schema.sql publisher
CSV_PATH="./goodreads_export-2023-10-17.csv"
# HEADER="$(<goodreads_header.txt)" # Save for future reference, very cool
HEADER=$(head -n 1 goodreads_export-2023-10-17.csv | sed 's/,/","/g; s/^/"/; s/$/"/')
psql -c "\COPY goodreads_books($HEADER) FROM '$CSV_PATH' DELIMITER ',' CSV HEADER;" publisher

# TODO: see if copilot chat will work with these comments.
# what we want to do next is to extract the headers from the csv file and use that to create the table,
# making sure that the headers are valid column names. Then we can use the \COPY command to import the data.

# Replication commands for the Docker subscriber database.
#
# Subscriber1
# Note: ensure there is no sequence table in the subscriber1 database.
PGPASSWORD=foobar psql -f books_schema.sql -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -c "CREATE SUBSCRIPTION sub1 CONNECTION 'host=host.docker.internal dbname=publisher' PUBLICATION bookspub;" -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -U postgres -p 5433 -h localhost -f ./goodreads_pub_schema.sql

# Create subscriber2 database
# Note: ensure there is no sequence table in the subscriber2 database.
PGPASSWORD=foobar psql -f books_schema.sql -U postgres -p 5434 -h localhost
PGPASSWORD=foobar psql -c "CREATE SUBSCRIPTION sub2 CONNECTION 'host=host.docker.internal dbname=publisher' PUBLICATION bookspub;" -U postgres -p 5434 -h localhost
PGPASSWORD=foobar psql -U postgres -p 5434 -h localhost -f ./goodreads_pub_schema.sql

# TODO: insert more, then update, then delete. Verify changes propagate to subscriber.

echo "All done"
