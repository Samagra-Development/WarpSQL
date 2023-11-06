#!/bin/bash
set -ex 

echo "Test pg_partman Extension"
psql -U postgres <<EOF
CREATE SCHEMA partman;
CREATE EXTENSION pg_partman SCHEMA partman;

EOF
              

              