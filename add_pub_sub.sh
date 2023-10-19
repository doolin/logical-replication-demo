#!/bin/bash

# This script assumes the databases all exist running on the appropriate ports,
# with the appropriate tables existing.

psql -c "CREATE PUBLICATION bookspub FOR TABLE books;" publisher
PGPASSWORD=foobar psql -c "CREATE SUBSCRIPTION sub1 CONNECTION 'host=host.docker.internal dbname=publisher' PUBLICATION bookspub;" -U postgres -p 5433 -h localhost
PGPASSWORD=foobar psql -c "CREATE SUBSCRIPTION sub2 CONNECTION 'host=host.docker.internal dbname=publisher' PUBLICATION bookspub;" -U postgres -p 5434 -h localhost

