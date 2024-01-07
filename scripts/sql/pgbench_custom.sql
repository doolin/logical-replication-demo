-- pgbench_custom.sql

\set id random(1, 5)
SELECT * FROM books WHERE id = :id;

