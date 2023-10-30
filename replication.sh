#!/bin/bash

# TODO: figure out how to handle created_at and updated_at compatible with Rails.
# TODO: insert more, then update, then delete. Verify changes propagate to subscriber.
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
psql -c "ALTER SYSTEM SET wal_level = logical;" publisher
psql -c "CREATE PUBLICATION leadership_pub FOR TABLE books where (topic = 'leadership');" publisher
psql -c "CREATE PUBLICATION technical_pub FOR TABLE books where (topic = 'technical');" publisher

# Now we need to restart
brew services restart postgresql@16
sleep 1 # wait for the server to restart

# Load up the goodreads export for fun.
psql -f ./goodreads_pub_schema.sql publisher
CSV_PATH="./goodreads_export-2023-10-17.csv"
# HEADER="$(<goodreads_header.txt)" # Save for future reference, very cool
HEADER=$(head -n 1 goodreads_export-2023-10-17.csv | sed 's/,/","/g; s/^/"/; s/$/"/')
psql -c "\COPY goodreads_books($HEADER) FROM '$CSV_PATH' DELIMITER ',' CSV HEADER;" publisher

# Replication commands for the Docker subscriber database.
# Create subscriber1 database
# Note: ensure there is no sequence table in the subscriber1 database.
PGPASSWORD=foobar psql -f books_schema.sql -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -c "CREATE SUBSCRIPTION sub1 CONNECTION 'host=host.docker.internal dbname=publisher' PUBLICATION leadership_pub;" -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -U postgres -p 5433 -h localhost -f ./goodreads_pub_schema.sql

# Create subscriber2 database
# Note: ensure there is no sequence table in the subscriber2 database.
PGPASSWORD=foobar psql -f books_schema.sql -U postgres -p 5434 -h localhost
PGPASSWORD=foobar psql -c "CREATE SUBSCRIPTION sub2 CONNECTION 'host=host.docker.internal dbname=publisher' PUBLICATION technical_pub;" -U postgres -p 5434 -h localhost
PGPASSWORD=foobar psql -U postgres -p 5434 -h localhost -f ./goodreads_pub_schema.sql

echo "All done"
