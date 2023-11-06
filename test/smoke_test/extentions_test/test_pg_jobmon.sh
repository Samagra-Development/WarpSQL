#!/bin/bash
set -ex 

echo "Test pg_jobmon Extension"
psql -c " CREATE SCHEMA jobmon;"
psql -c "CREATE EXTENSION pg_jobmon SCHEMA jobmon cascade;"