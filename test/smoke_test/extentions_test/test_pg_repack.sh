#!/bin/bash
set -ex 

echo "Test pg_repack Extension"
psql -c "CREATE EXTENSION pg_repack;"
psql -c "select repack.version(), repack.version_sql();"