#!/bin/bash
set -ex 

echo "Test zombodb Extension"
psql -c "CREATE EXTENSION zombodb;"
psql -c "SELECT zdb.internal_version();"
              
              

              