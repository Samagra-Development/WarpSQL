-- Test the connection to the database
SELECT 1;

-- Test the creation of a table
CREATE TABLE test (
  id serial PRIMARY KEY,
  name text
);

-- Test the insertion of a row into the table
INSERT INTO test (name) VALUES ('Test');

-- Test the retrieval of a row from the table
SELECT * FROM test;

-- Test the deletion of a row from the table
DELETE FROM test WHERE id = 1;

-- Test the drop of the table
DROP TABLE test;