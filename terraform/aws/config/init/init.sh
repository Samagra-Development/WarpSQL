# !/bin/bash
set -x
# ls -lah /usr/local/share/postgresql/
# sed -i 's/#wal_level = replica/wal_level = logical/' /usr/local/share/postgresql/postgresql.conf.sample
echo "host  replication  all   all   scram-sha-256" >> /var/lib/postgresql/data/pg_hba.conf #TODO limit the host