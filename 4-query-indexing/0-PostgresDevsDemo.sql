-- Show available extensions
select * from pg_available_extensions;

-- Azure Storage extension

-- Show extensions
show azure.extensions;

-- CREATE EXTENSION
CREATE EXTENSION azure_storage;
-- Add Account
SELECT azure_storage.account_add('<account>', '<key>');

-- Grant Permissions
GRANT azure_storage_admin TO support;
GRANT pg_read_server_files  to scoriani;

SELECT * FROM azure_storage.account_list();

-- Get Blobs
-- Get list of blobs:
SELECT path, bytes, pg_size_pretty(bytes), content_type
FROM azure_storage.blob_list('<account>','demo');

-- PostgreSQL Data Types and Indexes

DROP TABLE recipes;
-- Recipe Table
CREATE TABLE recipes (
    title text,
    ingredients text,
    directions text,
    link text,
    source text,
    NER text,
    site text
);

-- Copy from storage:
COPY recipes
FROM 'https://<account>.blob.core.windows.net/demo/recipes_data.csv'
WITH (FORMAT 'csv', header);

select * from recipes
limit 10;

CREATE TABLE employees (CustomerId int,LastName varchar(50),FirstName varchar(50));
INSERT INTO employees 
SELECT * FROM azure_storage.blob_get('<sccount>','mytestblob','employee.csv',options:= azure_storage.options_csv_get(header=>true)) AS res (
  CustomerId int,
  LastName varchar(50),
  FirstName varchar(50))

SELECT azure_storage.blob_put('<account>', 'mytestblob', 'employee2.csv', res) FROM (SELECT EmployeeId,LastName FROM employees) res;

-- GeoSpatial data types

create extension postgis;

-- Create a table with a geometry column
CREATE TABLE locations (
    location_name text,
    geom geometry(Point)
);

-- Insert geospatial data
INSERT INTO locations (location_name, geom)
VALUES ('Central Park', ST_GeomFromText('POINT(-73.968541 40.785091)', 4326));

-- Find locations within a radius
SELECT location_name
FROM locations
WHERE ST_DWithin(geom, ST_GeomFromText('POINT(-73.980357 40.785091)', 4326), 1000);


-- Range Types

-- Creating Range types
DROP TABLE IF EXISTS reservation;
CREATE TABLE reservation (room int, during tsrange);

CREATE INDEX reservation_idx ON reservation USING GIST (during);

INSERT INTO reservation VALUES
    (1108, '[2010-01-01 14:30, 2010-01-01 15:30)');

-- Containment check
SELECT int4range(10, 20) @> 3;

-- Overlap of range?
SELECT numrange(11.1, 22.2) && numrange(20.0, 30.0);

-- Extract the upper bound
SELECT upper(int8range(15, 25));

-- Compute the intersection
SELECT int4range(15, 20) * int4range(15, 25);

-- Is the range empty?
SELECT isempty(numrange(1, 5));

-- Create  range constraint
-- Key is room
CREATE EXTENSION btree_gist;

CREATE TABLE room_reservation (
    room text,
    during tsrange,
    EXCLUDE USING GIST (room WITH =, during WITH &&)
);

INSERT INTO room_reservation VALUES
    ('123A', '[2010-01-01 14:00, 2010-01-01 15:00)');

-- Should error out
INSERT INTO room_reservation VALUES
    ('123A', '[2010-01-01 14:30, 2010-01-01 15:30)');

-- works
INSERT INTO room_reservation VALUES
    ('123B', '[2010-01-01 14:30, 2010-01-01 15:30)');

-- Table Inheritence:
DROP TABLE IF EXISTS conference;
DROP TABLE IF EXISTS pass_conference

CREATE TABLE conference (
    session_id   int  NOT NULL PRIMARY KEY,
	session_title text,
    publish_date    date NOT NULL DEFAULT now()
);

CREATE TABLE pass_conference (
    pass_session_id    text NOT NULL,
	pass_room_number text NOT NULL
) INHERITS (conference);
										 								 
INSERT INTO conference (session_id,session_title) VALUES (1,'Intro to postgres');

INSERT INTO pass_conference
    (session_id, session_title,pass_session_id,pass_room_number) 
	VALUES (101,'AI with PostgreSQL', 'BKR01', '4A');

select * from conference;
select * from pass_conference;
										 
create extension postgis;

SELECT PostGIS_Full_Version()
