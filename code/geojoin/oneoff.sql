-- List all tables containing a geometry column
select table_name from information_schema.columns where column_name = 
'the_geom';

-- Get distances, clearly too slow and in cumbersome decimal degree units
select ST_Distance("kjgy-var8".the_geom, "kzjm-xkqj".the_geom) from "kjgy-var8", "kzjm-xkqj" limit 500;

-- Transform first into SRID 2855 (WA ST Plane N Harn, meters)
-- http://spatialreference.org/ref/epsg/2855/
SELECT ST_Distance(
       ST_Transform("kjgy-var8".the_geom, 2855),
       ST_Transform("kzjm-xkqj".the_geom, 2855)) <= 5
FROM "kjgy-var8", "kzjm-xkqj"
LIMIT 5;

-- Try distance approach with a where clause
SELECT count(*)
FROM "kjgy-var8", "kzjm-xkqj"
WHERE ST_Distance(
      ST_Transform("kjgy-var8".the_geom, 2855),
      ST_Transform("kzjm-xkqj".the_geom, 2855)) <= 5;

-- Same deal, but this time buffer the transformed geoms and test for intersect
SELECT count(*)
FROM "kjgy-var8", "kzjm-xkqj"
WHERE ST_Intersects(
      ST_Buffer(ST_Transform("kjgy-var8".the_geom, 2855), 5),
      ST_Buffer(ST_Transform("kzjm-xkqj".the_geom, 2855), 5));

-- Now create a new buffered geometry in appropriate datum, enable
-- spatial indexing, and see how that goes.
SELECT DropGeometryColumn('kjgy-var8', 'b_geom');
SELECT AddGeometryColumn('kjgy-var8', 'b_geom', 2855, 'POLYGON', 2);
UPDATE "kjgy-var8"
SET b_geom = ST_Buffer(ST_Transform(the_geom, 2855), 5);
CREATE INDEX "kjgy-var8_b_geom_index" ON "kjgy-var8" USING GIST (b_geom);

SELECT DropGeometryColumn('kzjm-xkqj', 'b_geom');
SELECT AddGeometryColumn('kzjm-xkqj', 'b_geom', 2855, 'POLYGON', 2);
UPDATE "kzjm-xkqj"
SET b_geom = ST_Buffer(ST_Transform(the_geom, 2855), 5);
CREATE INDEX "kzjm-xkqj_b_geom_index" ON "kzjm-xkqj" USING GIST (b_geom);

SELECT count(*)
FROM "kjgy-var8", "kzjm-xkqj"
WHERE ST_Intersects("kjgy-var8".b_geom, "kzjm-xkqj".b_geom);
