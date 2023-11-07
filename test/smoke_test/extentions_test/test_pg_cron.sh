#!/bin/bash
set -ex 

echo "Test pg_cron Extension"
psql -c "CREATE EXTENSION pg_cron;"
psql -c "SELECT cron.schedule('30 3 * * 6', $$DELETE FROM events WHERE event_time < now() - interval '1 week'$$);"