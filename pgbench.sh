#!/bin/bash

# DEFAULT_MEMORY="512m"
# MEMORY=$DEFAULT_MEMORY
DURATION=60
SCALE=10
CLIENTS=10
THREADS=3

# Function to show help
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -T <seconds>   Duration of the benchmark in seconds"
    echo "  -c <clients>   Number of clients to simulate"
    echo "  -j <threads>   Number of threads (jobs) to use, must be less than or equal to the number of clients"
    echo "  -h             Display this help and exit"
}

# Process command-line options
while getopts ":hT:c:j:" opt; do
    case ${opt} in
        h )
            show_help
            exit 0
            ;;
        T )
            DURATION="${OPTARG}"
            # Check if the provided duration is a number
            if ! [[ "$DURATION" =~ ^[0-9]+$ ]]; then
                echo "Invalid duration: $DURATION. Duration must be a number."
                exit 1
            fi
            ;;
        c )
            CLIENTS="${OPTARG}"
            # Check if the provided number of clients is a number
            if ! [[ "$CLIENTS" =~ ^[0-9]+$ ]]; then
                echo "Invalid number of clients: $CLIENTS. Number of clients must be a number."
                exit 1
            fi
            ;;
        j )
            THREADS="${OPTARG}"
            # Check if the provided number of threads is a number
            if ! [[ "$THREADS" =~ ^[0-9]+$ ]]; then
                echo "Invalid number of threads: $THREADS. Number of threads must be a number."
                exit 1
            fi
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            show_help
            exit 1
            ;;
        : )
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

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
    PGPASSWORD=foobar pgbench -h $HOST -p $PORT -U $PG_USER -i -s $SCALE $DB_NAME
fi

# Run the benchmark
# -T is duration in seconds
# -c is number of clients
# -j is number of threads, needs to be less than or equal to the number of clients
PGPASSWORD=foobar pgbench -h $HOST -p $PORT -U $PG_USER -T "$DURATION" -c "$CLIENTS" -j "$THREADS" $DB_NAME

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
