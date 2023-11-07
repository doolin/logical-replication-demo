#!/bin/bash

# TODO: figure out how to handle created_at and updated_at compatible with Rails.
# 1. these will have to be done using triggers.
# 2. do the created_at trigger first, then the updated_at trigger.
# 3. write some tests to verify the triggers work.

# TODO: load testing the pub/sub system.
# 1. Set up a publisher database in a container.
# 2. Write a script to load up the publisher database with a bunch of data. Use Faker.
# 3. Set up a subscriber database in a container.
# 4. Constrain the docker images resources.
# 5. Set up monitoring on the docker images using InfluxDB and Grafana.

# TODO: insert more, then update, then delete. Verify changes propagate to subscriber.
# TODO: investigate how index creation works with replication.
# TODO: due diligence on https://github.com/shayonj/pg_easy_replicate
# TODO: due diliegnce on pglogical

# TODO: install pghero if possible.

# TODO: constrain postgres to very few connections, say, 2.

# Publisher variables
PGPASSWORD="foobar"
PG_HOST="localhost"
PG_PORT="5435"
PG_USER="postgres"
DB_NAME="publisher"

# Function to run psql command
run_psql() {
  PGPASSWORD=foobar psql -p "$PG_PORT" -h "$PG_HOST" -U "$PG_USER" "$@"
}

# Prepare the publisher database.
# Reminder: -f loads a file, -c indicates a sql command to run.
run_psql -c "DROP DATABASE IF EXISTS $DB_NAME;" 2&> /dev/null
run_psql -c "CREATE DATABASE $DB_NAME;"
run_psql -f books_schema.sql -d "$DB_NAME" # -a to echo all
run_psql -c "CREATE SEQUENCE books_id_seq ;" -d "$DB_NAME"
run_psql -c "ALTER TABLE books ALTER COLUMN id SET DEFAULT nextval('books_id_seq');" -d "$DB_NAME"
run_psql -c "\COPY books ("sku", "title", "topic") FROM './books_data.csv' DELIMITER ',' CSV HEADER;" -d "$DB_NAME"

# Set up replication on the publisher database.
run_psql -c "ALTER SYSTEM SET wal_level = logical;" -d "$DB_NAME"
run_psql -c "ALTER SYSTEM SET listen_addresses = '*'; " -d "$DB_NAME"

docker cp publisher:/var/lib/postgresql/data/pg_hba.conf ./pg_hba.conf
echo "host all all all trust" >> pg_hba.conf
docker cp ./pg_hba.conf publisher:/var/lib/postgresql/data/pg_hba.conf
docker restart publisher
sleep 1 # wait for the server to restart

run_psql -c "CREATE PUBLICATION leadership_pub FOR TABLE books where (topic = 'leadership');"  -d "$DB_NAME"
run_psql -c "CREATE PUBLICATION technical_pub FOR TABLE books where (topic = 'technical');"  -d "$DB_NAME"
# Check with SELECT * FROM pg_publication;

# TODO: unify schema
run_psql -f ./goodreads_pub_schema.sql -d "$DB_NAME"
CSV_PATH="./goodreads_export-2023-10-17.csv"
HEADER=$(head -n 1 goodreads_export-2023-10-17.csv | sed 's/,/","/g; s/^/"/; s/$/"/')
run_psql -c "\COPY goodreads_books($HEADER) FROM '$CSV_PATH' DELIMITER ',' CSV HEADER;" -d "$DB_NAME"

# TODO: investigate how docker network operates in more detail.
# create the network if it doesn't exist, then connect the containers to the network.
docker network ls | grep -q "pubsub_network" || docker network create pubsub_network
docker network connect pubsub_network publisher
docker network connect pubsub_network subscriber1
docker network connect pubsub_network subscriber2

# Replication commands for the Docker subscriber database.
# Create subscriber1 database
# Note: ensure there is no sequence table in the subscriber1 database.
PGPASSWORD=foobar psql -f books_schema.sql -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -c "CREATE SUBSCRIPTION sub1 CONNECTION 'host=publisher dbname=publisher user=postgres password=foobar' PUBLICATION leadership_pub;" -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -U postgres -p 5433 -h localhost -f ./goodreads_pub_schema.sql

# Create subscriber2 database
# Note: ensure there is no sequence table in the subscriber2 database.
PGPASSWORD=foobar psql -f books_schema.sql -U postgres -p 5434 -h localhost
PGPASSWORD=foobar psql -c "CREATE SUBSCRIPTION sub2 CONNECTION 'host=publisher dbname=publisher user=postgres password=foobar' PUBLICATION technical_pub;" -U postgres -p 5434 -h localhost
PGPASSWORD=foobar psql -U postgres -p 5434 -h localhost -f ./goodreads_pub_schema.sql

echo "All done"
