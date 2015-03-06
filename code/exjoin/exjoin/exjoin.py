import pandas as pd
import gc, os, argparse, sys
from itertools import product, combinations, izip
from glob import glob
from multiprocessing import Pool, Lock

lock = Lock()

def cjoin(pathstuple):
    d0 = pd.read_csv(pathstuple[0], low_memory=False)
    d1 = pd.read_csv(pathstuple[1], low_memory=False)
    s0 = d0.apply(set, 1)
    s1 = d1.apply(set, 1)
    cols = product(s0, s1)
    names = product(d0.columns, d1.columns)
    res = []
    for c,n in izip(cols, names):
        l = len(c[0].intersection(c[1]))
        if l > 0:
            res.append('"{}","{}","{}","{}",{}'.(pathstuple[0], n[0], pathstuple[1], n[1], l))
        gc.collect()
    with lock:
        for x in res:
            print x
            
def main():
    parser = argparse.ArgumentParser(description="Exhaustively join set of csv files")
    parser.add_argument("csvpath", help="path to csv files to join")
    parser.add_argument("-w", "--workers", help="number of worker processes to spawn", default=2, type=int)
    args = parser.parse_args()

    filelist = glob(os.path.join(args.csvpath, "*.csv"))
    pathstuple = combinations(filelist, 2)

    p = Pool(args.workers)
    p.map(cjoin, pathstuple)


if __name__ == '__main__':
    main()
