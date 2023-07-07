#!/bin/bash
set -ex 

echo "Test PostGIS Extension"
psql -c "CREATE EXTENSION postgis;" || true
psql -c "SELECT PostGIS_Version();"

echo "Test PostGIS Geometry Function"
psql -c "CREATE TABLE test_geometry_table (id serial primary key, geom geometry(Point, 4326));"
psql -c "INSERT INTO test_geometry_table (geom) VALUES (ST_GeomFromText('POINT(0 0)', 4326));"
psql -c "SELECT * FROM test_geometry_table;"