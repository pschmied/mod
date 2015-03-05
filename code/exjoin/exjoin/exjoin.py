import pandas as pd
import gc, os, argparse, sys
from itertools import product, combinations
from glob import glob
from multiprocessing import Pool, Lock

lock = Lock()

def output(res):
    with lock:
        sys.stdout.write(res)

def cjoin(p0, p1):
    d0 = pd.read_csv(p0, low_memory=False)
    d1 = pd.read_csv(p1, low_memory=False)
    comb_col = product(d0.columns, d1.columns)
    res = []
    for c in comb_col:
        l = len(pd.merge(d0, d1, left_on=c[0],
                         right_on=c[1], sort=False))
        res.append("{}\t{}\t{}\t{}\t{}\n".format(p0, c[0], p1, c[1], l))
        gc.collect()
    for x in res:
        output(x)
            
def tjoin(x):
    cjoin(x[0], x[1])


def main():
    parser = argparse.ArgumentParser(description="Exhaustively join set of csv files")
    parser.add_argument("csvpath", help="path to csv files to join")
    parser.add_argument("-w", "--workers", help="number of worker processes to spawn", default=2)
    args = parser.parse_args()
    p = Pool(args.workers)
    filelist = glob(os.path.join(args.csvpath, "*.csv"))
    comb_file = combinations(filelist, 2)
    p.map(tjoin, comb_file)

if __name__ == '__main__':
    main()
