#!/bin/bash
# Usage: ./slurpsocrata identifierlist.txt apitoken

# Prototypical socrata URL looks like:
# https://data.seattle.gov/api/views/y6ef-jf2w/rows.csv?accessType=DOWNLOAD
# has

for f in $(cat $1)
do
        # if .csv file exists, read next file
	if [ -f ${f}.csv ]
	then
		echo "Skipping $f, file exists..."
		continue
	fi
        echo "Downloading $f"
        curl -H "X-App-Token: $2" -H 'Accept-Encoding: gzip,deflate' -o $f.csv https://data.seattle.gov/api/views/$f/rows.csv?accessType=DOWNLOAD
done
