# !/bin/bash
set -e
echo "host  replication  all   all   scram-sha-256" >> /var/lib/postgresql/data/pg_hba.conf 