#!/bin/bash
set -ex 

echo "Test HyperLogLog Extension"
psql -c "CREATE EXTENSION hll;"
psql -c "select hll_hash_text('hello world');"