#!/bin/bash
set -ex 

echo "Test Citus Extension"
psql -c "CREATE EXTENSION citus;"
psql -c "SELECT * FROM citus_version();"

echo "Test Citus Distributed Table"
psql -c "CREATE TABLE test_distributed_table (id serial primary key, data text);"
psql -c "SELECT create_distributed_table('test_distributed_table', 'id');"
psql -c "INSERT INTO test_distributed_table (data) VALUES ('test data');"
psql -c "SELECT * FROM test_distributed_table;"