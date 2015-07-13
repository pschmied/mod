import argparse, sys, psycopg2
from itertools import product, combinations, izip
#from glob import glob
#from multiprocessing import Pool, Lock

# dbcon = psycopg2.connect(dbname="mod")

def gjoin(dbcon, xname, yname):
    '''Takes a DB connection object, and two table names; prints the
    matching tables and the number of rows that met the criteria.

    '''

    c = dbcon.cursor()
    selstr = 'SELECT count(*) FROM "{}", "{}" WHERE ST_Intersects("{}".b_geom, "{}".b_geom)'.format(xname, yname, xname, yname)
    c.execute(selstr)
    match = c.fetchone()
    if match[0] > 0:
        sys.stdout.write('"{}", "{}", {}\n'.format(xname, yname, match[0]))
        sys.stdout.flush()
    


def buildindex(dbcon, tablename):
    '''Takes a db connection object, and a table name. Adds a new
    geometry column, transforms and creates a 5m buffer around each
    point, and finally builds a spatial index.

    '''
    print("Building geometry for table {}".format(tablename))
    c = dbcon.cursor()
    addstr = "SELECT AddGeometryColumn('{}', 'b_geom', 2855, 'POLYGON', 2);".format(tablename)
    updatestr = 'UPDATE "{}" SET b_geom = ST_Buffer(ST_Transform(the_geom, 2855), 5);'.format(tablename)
    idxstr = 'CREATE INDEX "{}_b_geom_index" ON "{}" USING GIST (b_geom);'.format(tablename, tablename)
    map(c.execute, [addstr,updatestr,idxstr])
    c.close()
    
def clearindex(dbcon, tablename):
    '''Drops any previously created geometry for our bufferred geometry'''

    c = dbcon.cursor()
    dropstr = "SELECT DropGeometryColumn('{}', 'b_geom');".format(tablename)
    try:
        c.execute(dropstr)
    except psycopg2.Error as e:
        print("unable to drop {}".format(tablename))
        pass
    c.close()
    
def listgeomtabs(dbcon):
    c = dbcon.cursor()
    selstr = "SELECT table_name from information_schema.columns where column_name = 'the_geom';"
    c.execute(selstr)
    res = c.fetchall()
    return([x[0] for x in res])
    
def main():
    parser = argparse.ArgumentParser(description="Test spatial intersection of points in many tables")
    parser.add_argument("dbname", help="name of db (assumes local, no-passwd access)")
    parser.add_argument('-i', '--index-rebuild', dest='idx', action='store_const',
                        const=True, default=False,
                        help='Rebuild spatial indices only and exit')
    args = parser.parse_args()

    dbcon = psycopg2.connect(dbname=args.dbname)
    dbcon.autocommit = True
    
    tabs = listgeomtabs(dbcon)

    if args.idx:
        map(lambda x: clearindex(dbcon, x), tabs)
        map(lambda x: buildindex(dbcon, x), tabs)
    else:
        tbpairs = combinations(tabs, 2)
        map(lambda x: gjoin(dbcon, x[0], x[1]), tbpairs)


if __name__ == '__main__':
    main()
