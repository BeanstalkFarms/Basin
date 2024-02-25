import argparse
from eth_abi import encode
from decimal import *
getcontext().prec = 40

def powuFraction(num, denom, exp):
    return (Decimal(num)/Decimal(denom))**Decimal(exp)

def main(args):
    powu = powuFraction(args.numerator, args.denominator, args.exponent) * (2**128)
    powu_enc = encode(['int256'], [int(powu)])
    print("0x" + powu_enc.hex())

# def test(args):
#     powu_fraction = powuFraction(args.numerator, args.denominator, args.exponent)
#     powu = powu_fraction * (2**128)
#     print(powu_fraction)
#     print('{:f}'.format(powu_fraction))
#     print(powu)

def parse_args(): 
    parser = argparse.ArgumentParser()
    parser.add_argument("--numerator", "-n", type=int)
    parser.add_argument("--denominator", "-d", type=int)
    parser.add_argument("--exponent", "-e", type=int)
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args()
    main(args)
    # test(args)