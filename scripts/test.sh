#!/bin/bash

# PostgreSQL Connection Variables
DB_NAME="postgres"
DB_USER="postgres"
DB_PASS="foobar"
DB_HOST="localhost"
DB_PORT="5433"

# This doesn't work, fix it later.
# COUNT_QUERY="SELECT COUNT(*) FROM books;"

ROW_COUNT=$(PGPASSWORD=$DB_PASS psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM books;")
ROW_COUNT=$(echo "$ROW_COUNT" | xargs)

if [ "$ROW_COUNT" -eq 2 ]; then
    echo "Subscriber 1 Test passed!"
else
    echo "Subscriber 1 Test failed!"
    echo "Expected: 2 rows. Found: $ROW_COUNT rows."
fi

DB_PORT="5434"
# Run the query to count rows in the books table
ROW_COUNT=$(PGPASSWORD=$DB_PASS psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM books;")
ROW_COUNT=$(echo "$ROW_COUNT" | xargs)

if [ "$ROW_COUNT" -eq 3 ]; then
    echo "Subscriber 2 Test passed!"
else
    echo "Subscriber 2 Test failed!"
    echo "Expected: 3 rows. Found: $ROW_COUNT rows."
fi

DB_PORT="5435"
DB_NAME="publisher"
# Run the query to count rows in the books table
ROW_COUNT=$(PGPASSWORD=$DB_PASS psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM books;")
# Remove leading/trailing white space from ROW_COUNT
ROW_COUNT=$(echo "$ROW_COUNT" | xargs)

if [ "$ROW_COUNT" -eq 5 ]; then
    echo "Publisher Test passed!"
else
    echo "Publisher Test failed!"
    echo "Expected: 5 rows. Found: $ROW_COUNT rows."
fi

DB_PORT="5435"

# Function to execute a SQL command and check its success
execute_and_check() {
    local command=$1
    local message=$2

    # TODO: refine the test conditions later.
    PGPASSWORD=$DB_PASS psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "$command" > /dev/null 2>&1

    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
        echo "Success: $message"
    else
        echo "Error: $message"
        exit 1
    fi
}

# Function to check if pg_stat_statements is loaded
check_pg_stat_statements() {
    echo "Checking if pg_stat_statements is loaded..."

    execute_and_check "SHOW shared_preload_libraries;" "SHOW shared_preload_libraries"
    execute_and_check "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;" "CREATE EXTENSION pg_stat_statements"
    execute_and_check "SELECT * FROM pg_stat_statements LIMIT 5;" "SELECT from pg_stat_statements"
}

# Main execution
check_pg_stat_statements
