import math

EXP_PRECISION = 1e12

class ConstantProduct:

    def __init__(self):
        pass

    def calcLPTokenUnderlying(
        self,
        lpTokenAmount,
        reserves,
        lpTokenSupply
    ):
        return [lpTokenAmount * r / lpTokenSupply for r in reserves]
    
    def calcLpTokenSupply(
        self,
        reserves
    ):
      return math.sqrt(reserves[0] * reserves[1] * EXP_PRECISION)

    def calcReserve(
        self,
        reserves,
        j,
        lpTokenSupply
    ):
        return (lpTokenSupply ** 2) / (reserves[0 if j == 1 else 1] * EXP_PRECISION)

    def calcReserveAtRatioSwap(
        self,
        reserves,
        j,
        ratios
    ):
        i = 0 if j == 1 else 1
        return math.sqrt((reserves[i] * reserves[j]) * (ratios[j] / ratios[i]))
    
    def calcReserveAtRatioLiquidity(
        self,
        reserves,
        j,
        ratios
    ):
        i = 0 if j == 1 else 1
        return reserves[i] * ratios[j] / ratios[i]
    
    def calcRate(
        self,
        reserves,
        i,
        j
    ):
        return reserves[i] / reserves[j]