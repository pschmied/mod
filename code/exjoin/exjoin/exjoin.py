import pandas as pd
import gc, os, argparse, sys
from itertools import product, combinations
from glob import glob
from multiprocessing import Pool, Lock

lock = Lock()

def output(res):
    with lock:
        sys.stdout.write(res)

def cjoin(pathstuple):
    d0 = pd.read_csv(pathstuple[0], low_memory=False)
    d1 = pd.read_csv(pathstuple[1], low_memory=False)
    s0 = d0.apply(set, 1)
    s1 = d1.apply(set, 1)
    cols = product(s0, s1)
    names = product(d0.columns, d1.columns)
    res = []
    for c,n in zip(cols, names):
        l = len(c[0].intersection(c[1]))
        res.append("{}\t{}\t{}\t{}\t{}\n".format(pathstuple[0], n[0], pathstuple[1], n[1], l))
        gc.collect()
    for x in res:
        output(x)
            
def main():
    parser = argparse.ArgumentParser(description="Exhaustively join set of csv files")
    parser.add_argument("csvpath", help="path to csv files to join")
    parser.add_argument("-w", "--workers", help="number of worker processes to spawn", default=2)
    args = parser.parse_args()

    p = Pool(args.workers)
    filelist = glob(os.path.join(args.csvpath, "*.csv"))
    pathstuple = combinations(filelist, 2)
    p.map(cjoin, pathstuple)

if __name__ == '__main__':
    main()
