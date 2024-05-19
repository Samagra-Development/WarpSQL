#!/bin/bash

create_sql=`mktemp`

log "INFO" "Starting TimescaleDB initialization script"

# Checks to support bitnami image with same scripts so they stay in sync
if [ ! -z "${BITNAMI_APP_NAME:-}" ]; then
	log "INFO" "Detected Bitnami environment"
	if [ -z "${POSTGRES_USER:-}" ]; then
		POSTGRES_USER=${POSTGRESQL_USERNAME}
	fi

	if [ -z "${POSTGRES_DB:-}" ]; then
		POSTGRES_DB=${POSTGRESQL_DATABASE}
	fi

	if [ -z "${PGDATA:-}" ]; then
		PGDATA=${POSTGRESQL_DATA_DIR}
	fi
fi

if [ -z "${POSTGRESQL_CONF_DIR:-}" ]; then
	POSTGRESQL_CONF_DIR=${PGDATA}
fi

cat <<EOF >${create_sql}
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
EOF

TS_TELEMETRY='basic'
if [ "${TIMESCALEDB_TELEMETRY:-}" == "off" ]; then
	echo "TimescaleDB telemetry is set to 'off'"
	TS_TELEMETRY='off'

	# We delete the job as well to ensure that we do not spam the
	# log with other messages related to the Telemetry job.
	cat <<EOF >>${create_sql}
SELECT alter_job(1,scheduled:=false);
EOF
fi

echo "Setting timescaledb.telemetry_level to ${TS_TELEMETRY}"
echo "timescaledb.telemetry_level=${TS_TELEMETRY}" >> ${POSTGRESQL_CONF_DIR}/postgresql.conf

export PGPASSWORD="$POSTGRESQL_PASSWORD"

# create extension timescaledb in initial databases
echo "Creating TimescaleDB extension in 'postgres' database"
psql -U "${POSTGRES_USER}" postgres -f ${create_sql}
echo "Creating TimescaleDB extension in 'template1' database"
psql -U "${POSTGRES_USER}" template1 -f ${create_sql}

if [ "${POSTGRES_DB:-postgres}" != 'postgres' ]; then
	echo "Creating TimescaleDB extension in '${POSTGRES_DB}' database"
    psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -f ${create_sql}
fi

echo "TimescaleDB initialization completed successfully"