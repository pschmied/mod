#!/usr/bin/env bash
# Restores a pg_dump after enabling postgis extension and lowercasing
# some key variables.
# Usage: restoredb.sh pgdump.gz dbname

dropdb $2
createdb $2
psql $2 -c "CREATE EXTENSION postgis;"

gzcat $1 |gsed s/Latitude/latitude/gI | gsed s/Longitude/longitude/gI| psql $2
