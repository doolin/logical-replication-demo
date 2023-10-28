#!/bin/bash

# PostgreSQL Connection Variables
DB_NAME="postgres"
DB_USER="postgres"
DB_PASS="foobar"
DB_HOST="localhost"
DB_PORT="5433"

# Run the query to count rows in the books table
ROW_COUNT=$(PGPASSWORD=$DB_PASS psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM books;")

# Remove leading/trailing white space from ROW_COUNT
ROW_COUNT=$(echo $ROW_COUNT | xargs)

# Check if the count is 5 and print the result
if [ "$ROW_COUNT" -eq 5 ]; then
    echo "Subscriber 1 Test passed!"
else
    echo "Subscriber 1 Test failed!"
    echo "Expected: 5 rows. Found: $ROW_COUNT rows."
fi

DB_PORT="5434"

# Run the query to count rows in the books table
ROW_COUNT=$(PGPASSWORD=$DB_PASS psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM books;")

# Remove leading/trailing white space from ROW_COUNT
ROW_COUNT=$(echo $ROW_COUNT | xargs)

# Check if the count is 5 and print the result
if [ "$ROW_COUNT" -eq 5 ]; then
    echo "Subscriber 2 Test passed!"
else
    echo "Subscriber 2 Test failed!"
    echo "Expected: 5 rows. Found: $ROW_COUNT rows."
fi
