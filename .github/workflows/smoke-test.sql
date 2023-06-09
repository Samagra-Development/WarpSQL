-- smoke-test.sql

-- Test Citus Extension
CREATE EXTENSION citus;
SELECT * FROM citus_version();

-- Test Citus Distributed Table
CREATE TABLE test_distributed_table (id serial primary key, data text);
SELECT create_distributed_table('test_distributed_table', 'id');
INSERT INTO test_distributed_table (data) VALUES ('test data');
SELECT * FROM test_distributed_table;

-- Test PostGIS Extension
CREATE EXTENSION postgis;
SELECT PostGIS_Version();

-- Test PostGIS Geometry Function
CREATE TABLE test_geometry_table (id serial primary key, geom geometry(Point, 4326));
INSERT INTO test_geometry_table (geom) VALUES (ST_GeomFromText('POINT(0 0)', 4326));
SELECT * FROM test_geometry_table;

-- Test zombodb Extension
CREATE EXTENSION zombodb;
SELECT zdb.internal_version();

-- Test pg_repack Extension
CREATE EXTENSION pg_repack;
SELECT repack.version(), repack.version_sql();

-- Test pgautofailover Extension
CREATE EXTENSION pgautofailover CASCADE;
SELECT pgautofailover.formation_settings();
