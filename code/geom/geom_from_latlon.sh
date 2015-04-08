#!/usr/bin/env bash
# Recover point latitude / longitude geometries in tables of a
# database.
#
# Usage: ./geom_from_latlon.sh tablelisting.txt postgisdb


for tab in `cat $1`; do
    echo "trying $tab"
    echo "ALTER TABLE \"$tab\" ADD COLUMN the_geom geometry(Point,4326); UPDATE \"$tab\" SET the_geom = ST_SetSRID(ST_MakePoint(Longitude, Latitude) ,4326);" | psql $2;
done
