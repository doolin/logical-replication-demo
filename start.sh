#!/bin/bash


docker container prune
docker system prune

# Get a fresh postgres:

docker pull postgres

# docker run  -e POSTGRES_PASSWORD=foobar -p 127.0.0.1:5433:5433 -d postgres

# docker run --name docker-post -p 5433:5432 -e POSTGRES_PASSWORD=foobar -d postgres
# from a `docker build -t localpost:13 .`
docker run \
  --name docker-post-10 -p 5433:5432 -e POSTGRES_PASSWORD=foobar \
  localpost:13

  # -v $CUSTOM_CONFIG:/etc/postgres/postgresql.conf \
  # postgres -c config_file=/etc/postgresql/postgresql.conf
#  -c max_replication_slots=15

# docker run -e POSTGRES_PASSWORD=foobar -d postgres
