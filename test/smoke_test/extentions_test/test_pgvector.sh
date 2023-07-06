#!/bin/bash
set -ex 

echo "Test pg_vector Extension"
psql -c "CREATE EXTENSION vector;"
psql -c "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));"
psql -c "INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');"
psql -c "SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 5;"