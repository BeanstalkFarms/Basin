import argparse
from eth_abi import encode
from decimal import *
getcontext().prec = 40
from ConstantProduct import ConstantProduct

def printIfV(message, v):
    if (v):
        print(message)

def capReserves(wf, xs_last_l, xs_t, capExponent, max_lp_increase, max_lp_decrease, max_rs, verbose=False):
    # Put a cap to prevent overflow
    if capExponent > 14000:
        capExponent = 14000


    # xs_rate_t = cap_ratios(wf, xs_last_l, xs_t, capExponent, max_rs, verbose)
    xs_rate_t = cap_lp_supply(wf, xs_last_l, xs_t, capExponent, max_lp_increase, max_lp_decrease)

    printIfV("Partial: " + str(xs_rate_t), verbose)

    # return cap_lp_supply(wf, xs_last_l, xs_rate_t, capExponent, max_lp_increase, max_lp_decrease)
    return cap_ratios(wf, xs_last_l, xs_rate_t, capExponent, max_rs, verbose)


def cap_ratios(wf, xs_last_l, xs_t, capExponent, max_rs, verbose=False):
    # Step 1 - Cap Rates
    r_01_last_l = wf.calcRate(xs_last_l, 0, 1)
    # Put a cap to prevent overflow
    if capExponent > 14000:
        capExponent = 14000
    printIfV((1 + max_rs[0][1])**capExponent, verbose)
    printIfV((1 - max_rs[1][0])**capExponent, verbose)
    rs_max_t = [
        [
            0,
            r_01_last_l * (1 + max_rs[0][1])**capExponent,
        ],

        [
            1 / r_01_last_l * (1 + max_rs[1][0])**capExponent,
            0
        ]
    ]
    printIfV(rs_max_t, verbose)
    xs_rate_t = xs_t[:]
    if (xs_t[0] / xs_t[1] > rs_max_t[0][1]):
        xs_rate_t[0] = wf.calcReserveAtRatioSwap(xs_t, 0, [rs_max_t[0][1], 1])
        xs_rate_t[1] = wf.calcReserveAtRatioSwap(xs_t, 1, [rs_max_t[0][1], 1])
    elif (xs_t[1] / xs_t[0] > rs_max_t[1][0]):
        xs_rate_t[0] = wf.calcReserveAtRatioSwap(xs_t, 0, [1, rs_max_t[1][0]])
        xs_rate_t[1] = wf.calcReserveAtRatioSwap(xs_t, 1, [1, rs_max_t[1][0]])
    return xs_rate_t

def cap_lp_supply(wf, xs_last_l, xs_rate_t, capExponent, max_lp_increase, max_lp_decrease):
    # Step 2 - Cap Magnitudes

    k_last_l = wf.calcLpTokenSupply(xs_last_l)
    k_rate_t = wf.calcLpTokenSupply(xs_rate_t)

    k_max_t = k_last_l * (1 + max_lp_increase)**capExponent
    k_min_t = k_last_l * (1 - max_lp_decrease)**capExponent

    xs_last_t = xs_rate_t

    if (k_rate_t > k_max_t):
        xs_last_t = wf.calcLPTokenUnderlying(k_max_t, xs_rate_t, k_rate_t)
    elif (k_rate_t < k_min_t):
        xs_last_t = wf.calcLPTokenUnderlying(k_min_t, xs_rate_t, k_rate_t)
    return xs_last_t

def main(args):
    wf = ConstantProduct()
    [reserve0, reserve1] = capReserves(
        wf,
        [args.last_reserve0, args.last_reserve1],
        [args.reserve0, args.reserve1],
        args.capExponent,
        args.max_lp_increase / 1e18,
        args.max_lp_decrease / 1e18,
        [[0, args.max_ratio_changes_01 / 1e18], [args.max_ratio_changes_10 / 1e18, 0]]
    )
    powu_enc = encode(['uint256', 'uint256'], [int(reserve0), int(reserve1)])
    print("0x" + powu_enc.hex())

def test(args):
    wf = ConstantProduct()
    [reserve0, reserve1] = capReserves(
        wf,
        [args.last_reserve0, args.last_reserve1],
        [args.reserve0, args.reserve1],
        args.capExponent,
        args.max_lp_increase / 1e18,
        args.max_lp_decrease / 1e18,
        [[0, args.max_ratio_changes_01 / 1e18], [args.max_ratio_changes_10 / 1e18, 0]],
        True
    )
    print(int(reserve0), int(reserve1))

def parse_args(): 
    parser = argparse.ArgumentParser()
    parser.add_argument("--reserve0", "-r0", type=int)
    parser.add_argument("--reserve1", "-r1", type=int)
    parser.add_argument("--last_reserve0", "-l0", type=int)
    parser.add_argument("--last_reserve1", "-l1", type=int)
    parser.add_argument("--capExponent", "-c", type=int)
    parser.add_argument("--max_lp_increase", "-mi", type=int)
    parser.add_argument("--max_lp_decrease", "-md", type=int)
    parser.add_argument("--max_ratio_changes_01", "-mr01", type=int)
    parser.add_argument("--max_ratio_changes_10", "-mr10", type=int)
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args()
    main(args)
    # test(args)
