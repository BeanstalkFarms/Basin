import os
import argparse
from eth_abi import decode
from decimal import *
import pandas as pd
import numpy as np

def main(args):
    val = decode(['(uint256,uint256,uint256,uint256)[]'], bytes.fromhex(args.data[2:]))
    arr = np.asarray(val[0])
    pd.DataFrame(
        arr,
        columns=['j', 'prev', 'curr', 'capped']
    ).to_csv(
        os.path.join("test", "output", f"{args.name}.csv"),
        index=False
    )
    print("Done")

def parse_args(): 
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", "-d", type=str)
    parser.add_argument("--name", "-n", type=str)
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args()
    main(args)