#!/bin/bash

# TODO: parameterize the pg bench arguments

DB_NAME="publisher"
PG_USER="postgres"
HOST="localhost"
PORT=5435

# Check if pgbench has been initialized
if PGPASSWORD=foobar psql -h $HOST -p $PORT -U $PG_USER -d $DB_NAME \
   -c "SELECT 'table_exists' WHERE EXISTS (SELECT FROM pg_tables WHERE tablename = 'pgbench_accounts');" \
   | grep -q 'table_exists'
then
    echo "pgbench already initialized."
else
    echo "Initializing pgbench..."
    # Initialize the database
    # -s is scale factor
    # -i is initialize
    PGPASSWORD=foobar pgbench -h $HOST -p $PORT -U $PG_USER -i -s 10 $DB_NAME
fi

# Run the benchmark
# -T is duration in seconds
# -c is number of clients
# -j is number of threads
PGPASSWORD=foobar pgbench -h $HOST -p $PORT -U $PG_USER -T 600 -c 10 -j 2 $DB_NAME

# This is a second benchmark to run in parallel
# This should go away once the script is parameterized
# PGPASSWORD=foobar pgbench -h localhost -p 5435 -U postgres -T 60 -c 2 -j 2 publisher


# TODO: clean up the database
# Function to drop a table
# drop_table() {
#     local table=$1
#     psql -U "$PG_USER" -d "$DB_NAME" -c "DROP TABLE IF EXISTS $table;"
# }

# echo "Cleaning up pgbench tables..."

# # Drop the pgbench tables
# drop_table pgbench_accounts
# drop_table pgbench_branches
# drop_table pgbench_history
# drop_table pgbench_tellers

# echo "Cleanup completed."
