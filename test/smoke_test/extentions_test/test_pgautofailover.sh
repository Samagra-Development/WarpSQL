#!/bin/bash
set -ex 

echo "Test pgautofailover Extension"
psql -c "CREATE EXTENSION pgautofailover CASCADE;"
psql -c "SELECT pgautofailover.formation_settings();"