-- Create extension
create extension postgis

-- nyc database
SELECT * FROM geometry_columns;

--The SRID corresponds to a spatial reference system based on the specific ellipsoid used for either flat-earth mapping or round-earth mapping
SELECT srtext FROM spatial_ref_sys
WHERE SRID = 26918;

-- Pgadmin has a Geometry viewer.
select name, ST_Transform(geom,4326)
from nyc_neighborhoods
where  name = 'East Village'
 
 -- Get Area
  SELECT ST_Area(geom)
  FROM nyc_neighborhoods
  WHERE name = 'East Village';
  
  -- Group by type, length of streets  
SELECT type, Sum(ST_Length(geom)) AS length
FROM nyc_streets
GROUP BY type
ORDER BY length DESC;

-- intersection 
SELECT name, ST_AsText(geom)
FROM nyc_subway_stations
WHERE name = 'Broad St';

SELECT name, boroname
FROM nyc_neighborhoods
WHERE ST_Intersects(geom, ST_GeomFromText('POINT(583571 4506714)',26918));


-- Streets within 20 meters of stop
SELECT name
FROM nyc_streets
WHERE ST_DWithin(
        geom,
        ST_GeomFromText('POINT(583571 4506714)',26918),
        10
      );
	  
-- Population within a distance
SELECT ST_AsText(geom)
  FROM nyc_streets
  WHERE name = 'Atlantic Commons';

SELECT Sum(popn_total)
  FROM nyc_census_blocks
  WHERE ST_DWithin(
   geom,
   ST_GeomFromText('LINESTRING(586782 4504202,586864 4504216)', 26918),
   50
  );
  
 -- Neighborhood that has BroadSt as station
 SELECT
  subways.name AS subway_name,
  neighborhoods.name AS neighborhood_name,
  neighborhoods.boroname AS borough
FROM nyc_neighborhoods AS neighborhoods
JOIN nyc_subway_stations AS subways
ON ST_Contains(neighborhoods.geom, subways.geom)
WHERE subways.name = 'Broad St';

-- Intersection .
-- Highest population density/km 
SELECT
  n.name,
  Sum(c.popn_total) / (ST_Area(n.geom) / 1000000.0) AS popn_per_sqkm
FROM nyc_census_blocks AS c
JOIN nyc_neighborhoods AS n
ON ST_Intersects(c.geom, n.geom)
GROUP BY n.name, n.geom
ORDER BY popn_per_sqkm DESC LIMIT 2;


-- What neighborhoods served by the 6 train?
SELECT DISTINCT n.name, n.boroname
FROM nyc_subway_stations AS s
JOIN nyc_neighborhoods AS n
ON ST_Contains(n.geom, s.geom)
WHERE strpos(s.routes,'6') > 0;


-- INdexing
DROP INDEX nyc_census_blocks_geom_idx;

explain analyze SELECT count(blocks.blkid)
 FROM nyc_census_blocks blocks
 JOIN nyc_subway_stations subways
 ON ST_Contains(blocks.geom, subways.geom)
 WHERE subways.name LIKE 'B%';
 
 CREATE INDEX nyc_census_blocks_geom_idx
 ON nyc_census_blocks
 USING GIST (geom);
  
 
