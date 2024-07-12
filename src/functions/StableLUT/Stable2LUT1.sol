// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ILookupTable} from "src/interfaces/ILookupTable.sol";

/**
 * @title BasinStableswapLookupTable
 * @dev This contract implements a lookup table of estimations used in the stableswap well function
 * to calculate the token ratios in a stableswap pool to return to peg.
 * It uses an if ladder structured as a binary tree to store and retrieve
 * price-to-token ratio estimates needed for liquidity and swap operations
 * within Beanstalk in O(1) time complexity.
 * A lookup table was used to avoid the need for expensive calculations on-chain.
 */
contract Stable2LUT1 is ILookupTable {
    /**
     * @notice Returns the amplification coefficient (A parameter) used to calculate the estimates.
     * @return The amplification coefficient.
     */
    function getAParameter() external pure returns (uint256) {
        return 1;
    }

    /**
     * @notice Returns the estimated range of reserve ratios for a given price,
     * assuming one token reserve remains constant.
     * Needed to calculate the liquidity of a well for Beanstalk to return to peg.
     * Used in `calcReserveAtRatioLiquidity` function in the stableswap well function.
     */
    function getRatiosFromPriceLiquidity(uint256 price) external pure returns (PriceData memory) {
        if (price < 1.0259e6) {
            if (price < 0.5719e6) {
                if (price < 0.4096e6) {
                    if (price < 0.3397e6) {
                        if (price < 0.3017e6) {
                            if (price < 0.2898e6) {
                                if (price < 0.0108e6) {
                                    revert("LUT: Invalid price");
                                } else {
                                    return PriceData(
                                        0.2898e6,
                                        0e18,
                                        703_998_871_212_465_767e18,
                                        0.0108e6,
                                        0e18,
                                        200_000_000_000_000_009e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.3009e6) {
                                    return PriceData(
                                        0.3017e6,
                                        0e18,
                                        670_475_115_440_443_486e18,
                                        0.2898e6,
                                        0e18,
                                        703_998_871_212_465_767e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.3017e6,
                                        0e18,
                                        670_475_115_440_443_486e18,
                                        0.3009e6,
                                        0e18,
                                        672_749_994_932_561_176e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.3252e6) {
                                if (price < 0.314e6) {
                                    return PriceData(
                                        0.3252e6,
                                        0e18,
                                        611_590_904_484_146_475e18,
                                        0.3017e6,
                                        0e18,
                                        670_475_115_440_443_486e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.3252e6,
                                        0e18,
                                        611_590_904_484_146_475e18,
                                        0.314e6,
                                        0e18,
                                        638_547_728_990_898_583e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.3267e6) {
                                    return PriceData(
                                        0.3397e6,
                                        0e18,
                                        579_181_613_597_186_854e18,
                                        0.3252e6,
                                        0e18,
                                        611_590_904_484_146_475e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.3397e6,
                                        0e18,
                                        579_181_613_597_186_854e18,
                                        0.3267e6,
                                        0e18,
                                        608_140_694_277_046_234e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.3777e6) {
                            if (price < 0.353e6) {
                                if (price < 0.3508e6) {
                                    return PriceData(
                                        0.353e6,
                                        0e18,
                                        551_601_536_759_225_600e18,
                                        0.3397e6,
                                        0e18,
                                        579_181_613_597_186_854e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.353e6,
                                        0e18,
                                        551_601_536_759_225_600e18,
                                        0.3508e6,
                                        0e18,
                                        555_991_731_349_224_049e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.3667e6) {
                                    return PriceData(
                                        0.3777e6,
                                        0e18,
                                        505_447_028_499_294_502e18,
                                        0.353e6,
                                        0e18,
                                        551_601_536_759_225_600e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.3777e6,
                                        0e18,
                                        505_447_028_499_294_502e18,
                                        0.3667e6,
                                        0e18,
                                        525_334_796_913_548_043e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.395e6) {
                                if (price < 0.3806e6) {
                                    return PriceData(
                                        0.395e6,
                                        0e18,
                                        476_494_146_860_361_123e18,
                                        0.3777e6,
                                        0e18,
                                        505_447_028_499_294_502e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.395e6,
                                        0e18,
                                        476_494_146_860_361_123e18,
                                        0.3806e6,
                                        0e18,
                                        500_318_854_203_379_155e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.4058e6) {
                                    return PriceData(
                                        0.4096e6,
                                        0e18,
                                        453_803_949_390_820_058e18,
                                        0.395e6,
                                        0e18,
                                        476_494_146_860_361_123e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.4096e6,
                                        0e18,
                                        453_803_949_390_820_058e18,
                                        0.4058e6,
                                        0e18,
                                        459_497_298_635_722_250e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    }
                } else {
                    if (price < 0.4972e6) {
                        if (price < 0.4553e6) {
                            if (price < 0.4351e6) {
                                if (price < 0.4245e6) {
                                    return PriceData(
                                        0.4351e6,
                                        0e18,
                                        417_724_816_941_565_672e18,
                                        0.4096e6,
                                        0e18,
                                        453_803_949_390_820_058e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.4351e6,
                                        0e18,
                                        417_724_816_941_565_672e18,
                                        0.4245e6,
                                        0e18,
                                        432_194_237_515_066_645e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.4398e6) {
                                    return PriceData(
                                        0.4553e6,
                                        0e18,
                                        392_012_913_845_865_367e18,
                                        0.4351e6,
                                        0e18,
                                        417_724_816_941_565_672e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.4553e6,
                                        0e18,
                                        392_012_913_845_865_367e18,
                                        0.4398e6,
                                        0e18,
                                        411_613_559_538_158_684e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.4712e6) {
                                if (price < 0.4656e6) {
                                    return PriceData(
                                        0.4712e6,
                                        0e18,
                                        373_345_632_234_157_500e18,
                                        0.4553e6,
                                        0e18,
                                        392_012_913_845_865_367e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.4712e6,
                                        0e18,
                                        373_345_632_234_157_500e18,
                                        0.4656e6,
                                        0e18,
                                        379_749_833_583_241_466e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.4873e6) {
                                    return PriceData(
                                        0.4972e6,
                                        0e18,
                                        345_227_121_439_310_375e18,
                                        0.4712e6,
                                        0e18,
                                        373_345_632_234_157_500e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.4972e6,
                                        0e18,
                                        345_227_121_439_310_375e18,
                                        0.4873e6,
                                        0e18,
                                        355_567_268_794_435_702e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.5373e6) {
                            if (price < 0.5203e6) {
                                if (price < 0.5037e6) {
                                    return PriceData(
                                        0.5203e6,
                                        0e18,
                                        322_509_994_371_370_222e18,
                                        0.4972e6,
                                        0e18,
                                        345_227_121_439_310_375e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.5203e6,
                                        0e18,
                                        322_509_994_371_370_222e18,
                                        0.5037e6,
                                        0e18,
                                        338_635_494_089_938_733e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.5298e6) {
                                    return PriceData(
                                        0.5373e6,
                                        0e18,
                                        307_152_375_591_781_169e18,
                                        0.5203e6,
                                        0e18,
                                        322_509_994_371_370_222e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.5373e6,
                                        0e18,
                                        307_152_375_591_781_169e18,
                                        0.5298e6,
                                        0e18,
                                        313_842_837_672_100_360e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.5633e6) {
                                if (price < 0.5544e6) {
                                    return PriceData(
                                        0.5633e6,
                                        0e18,
                                        285_311_670_611_000_293e18,
                                        0.5373e6,
                                        0e18,
                                        307_152_375_591_781_169e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.5633e6,
                                        0e18,
                                        285_311_670_611_000_293e18,
                                        0.5544e6,
                                        0e18,
                                        292_526_071_992_172_539e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.5719e6,
                                    0e18,
                                    278_596_259_040_164_302e18,
                                    0.5633e6,
                                    0e18,
                                    285_311_670_611_000_293e18,
                                    1e18
                                );
                            }
                        }
                    }
                }
            } else {
                if (price < 0.7793e6) {
                    if (price < 0.6695e6) {
                        if (price < 0.6256e6) {
                            if (price < 0.5978e6) {
                                if (price < 0.5895e6) {
                                    return PriceData(
                                        0.5978e6,
                                        0e18,
                                        259_374_246_010_000_262e18,
                                        0.5719e6,
                                        0e18,
                                        278_596_259_040_164_302e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.5978e6,
                                        0e18,
                                        259_374_246_010_000_262e18,
                                        0.5895e6,
                                        0e18,
                                        265_329_770_514_442_160e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.6074e6) {
                                    return PriceData(
                                        0.6256e6,
                                        0e18,
                                        240_661_923_369_108_501e18,
                                        0.5978e6,
                                        0e18,
                                        259_374_246_010_000_262e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.6256e6,
                                        0e18,
                                        240_661_923_369_108_501e18,
                                        0.6074e6,
                                        0e18,
                                        252_695_019_537_563_946e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.6439e6) {
                                if (price < 0.6332e6) {
                                    return PriceData(
                                        0.6439e6,
                                        0e18,
                                        229_201_831_780_103_315e18,
                                        0.6256e6,
                                        0e18,
                                        240_661_923_369_108_501e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.6439e6,
                                        0e18,
                                        229_201_831_780_103_315e18,
                                        0.6332e6,
                                        0e18,
                                        235_794_769_100_000_184e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.6625e6) {
                                    return PriceData(
                                        0.6695e6,
                                        0e18,
                                        214_358_881_000_000_155e18,
                                        0.6439e6,
                                        0e18,
                                        229_201_831_780_103_315e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.6695e6,
                                        0e18,
                                        214_358_881_000_000_155e18,
                                        0.6625e6,
                                        0e18,
                                        218_287_458_838_193_622e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.7198e6) {
                            if (price < 0.7005e6) {
                                if (price < 0.6814e6) {
                                    return PriceData(
                                        0.7005e6,
                                        0e18,
                                        197_993_159_943_939_803e18,
                                        0.6695e6,
                                        0e18,
                                        214_358_881_000_000_155e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7005e6,
                                        0e18,
                                        197_993_159_943_939_803e18,
                                        0.6814e6,
                                        0e18,
                                        207_892_817_941_136_807e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.7067e6) {
                                    return PriceData(
                                        0.7198e6,
                                        0e18,
                                        188_564_914_232_323_597e18,
                                        0.7005e6,
                                        0e18,
                                        197_993_159_943_939_803e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7198e6,
                                        0e18,
                                        188_564_914_232_323_597e18,
                                        0.7067e6,
                                        0e18,
                                        194_871_710_000_000_090e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.7449e6) {
                                if (price < 0.7394e6) {
                                    return PriceData(
                                        0.7449e6,
                                        0e18,
                                        177_156_100_000_000_082e18,
                                        0.7198e6,
                                        0e18,
                                        188_564_914_232_323_597e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7449e6,
                                        0e18,
                                        177_156_100_000_000_082e18,
                                        0.7394e6,
                                        0e18,
                                        179_585_632_602_212_943e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.7592e6) {
                                    return PriceData(
                                        0.7793e6,
                                        0e18,
                                        162_889_462_677_744_172e18,
                                        0.7449e6,
                                        0e18,
                                        177_156_100_000_000_082e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7793e6,
                                        0e18,
                                        162_889_462_677_744_172e18,
                                        0.7592e6,
                                        0e18,
                                        171_033_935_811_631_375e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    }
                } else {
                    if (price < 0.8845e6) {
                        if (price < 0.8243e6) {
                            if (price < 0.7997e6) {
                                if (price < 0.784e6) {
                                    return PriceData(
                                        0.7997e6,
                                        0e18,
                                        155_132_821_597_851_585e18,
                                        0.7793e6,
                                        0e18,
                                        162_889_462_677_744_172e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7997e6,
                                        0e18,
                                        155_132_821_597_851_585e18,
                                        0.784e6,
                                        0e18,
                                        161_051_000_000_000_047e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.8204e6) {
                                    return PriceData(
                                        0.8243e6,
                                        0e18,
                                        146_410_000_000_000_016e18,
                                        0.7997e6,
                                        0e18,
                                        155_132_821_597_851_585e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.8243e6,
                                        0e18,
                                        146_410_000_000_000_016e18,
                                        0.8204e6,
                                        0e18,
                                        147_745_544_378_906_267e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.8628e6) {
                                if (price < 0.8414e6) {
                                    return PriceData(
                                        0.8628e6,
                                        0e18,
                                        134_009_564_062_499_995e18,
                                        0.8243e6,
                                        0e18,
                                        146_410_000_000_000_016e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.8628e6,
                                        0e18,
                                        134_009_564_062_499_995e18,
                                        0.8414e6,
                                        0e18,
                                        140_710_042_265_625_000e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.8658e6) {
                                    return PriceData(
                                        0.8845e6,
                                        0e18,
                                        127_628_156_249_999_999e18,
                                        0.8628e6,
                                        0e18,
                                        134_009_564_062_499_995e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.8845e6,
                                        0e18,
                                        127_628_156_249_999_999e18,
                                        0.8658e6,
                                        0e18,
                                        133_100_000_000_000_010e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.9523e6) {
                            if (price < 0.9087e6) {
                                if (price < 0.9067e6) {
                                    return PriceData(
                                        0.9087e6,
                                        0e18,
                                        120_999_999_999_999_999e18,
                                        0.8845e6,
                                        0e18,
                                        127_628_156_249_999_999e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.9087e6,
                                        0e18,
                                        120_999_999_999_999_999e18,
                                        0.9067e6,
                                        0e18,
                                        121_550_625_000_000_001e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.9292e6) {
                                    return PriceData(
                                        0.9523e6,
                                        0e18,
                                        110_250_000_000_000_006e18,
                                        0.9087e6,
                                        0e18,
                                        120_999_999_999_999_999e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.9523e6,
                                        0e18,
                                        110_250_000_000_000_006e18,
                                        0.9292e6,
                                        0e18,
                                        115_762_500_000_000_006e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.9758e6) {
                                if (price < 0.9534e6) {
                                    return PriceData(
                                        0.9758e6,
                                        0e18,
                                        105_000_000_000_000_006e18,
                                        0.9523e6,
                                        0e18,
                                        110_250_000_000_000_006e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.9758e6,
                                        0e18,
                                        105_000_000_000_000_006e18,
                                        0.9534e6,
                                        0e18,
                                        110_000_000_000_000_000e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.0259e6,
                                    0e18,
                                    950_000_000_000_000_037e18,
                                    0.9758e6,
                                    0e18,
                                    105_000_000_000_000_006e18,
                                    1e18
                                );
                            }
                        }
                    }
                }
            }
        } else {
            if (price < 1.8687e6) {
                if (price < 1.3748e6) {
                    if (price < 1.1729e6) {
                        if (price < 1.1084e6) {
                            if (price < 1.0541e6) {
                                if (price < 1.0526e6) {
                                    return PriceData(
                                        1.0541e6,
                                        0e18,
                                        899_999_999_999_999_958e18,
                                        1.0259e6,
                                        0e18,
                                        950_000_000_000_000_037e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.0541e6,
                                        0e18,
                                        899_999_999_999_999_958e18,
                                        1.0526e6,
                                        0e18,
                                        902_500_000_000_000_015e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.0801e6) {
                                    return PriceData(
                                        1.1084e6,
                                        0e18,
                                        814_506_250_000_000_029e18,
                                        1.0541e6,
                                        0e18,
                                        899_999_999_999_999_958e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.1084e6,
                                        0e18,
                                        814_506_250_000_000_029e18,
                                        1.0801e6,
                                        0e18,
                                        857_374_999_999_999_981e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.1377e6) {
                                if (price < 1.1115e6) {
                                    return PriceData(
                                        1.1377e6,
                                        0e18,
                                        773_780_937_499_999_954e18,
                                        1.1084e6,
                                        0e18,
                                        814_506_250_000_000_029e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.1377e6,
                                        0e18,
                                        773_780_937_499_999_954e18,
                                        1.1115e6,
                                        0e18,
                                        810_000_000_000_000_029e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.1679e6) {
                                    return PriceData(
                                        1.1729e6,
                                        0e18,
                                        729_000_000_000_000_039e18,
                                        1.1377e6,
                                        0e18,
                                        773_780_937_499_999_954e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.1729e6,
                                        0e18,
                                        729_000_000_000_000_039e18,
                                        1.1679e6,
                                        0e18,
                                        735_091_890_625_000_016e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 1.2653e6) {
                            if (price < 1.2316e6) {
                                if (price < 1.1992e6) {
                                    return PriceData(
                                        1.2316e6,
                                        0e18,
                                        663_420_431_289_062_394e18,
                                        1.1729e6,
                                        0e18,
                                        729_000_000_000_000_039e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.2316e6,
                                        0e18,
                                        663_420_431_289_062_394e18,
                                        1.1992e6,
                                        0e18,
                                        698_337_296_093_749_868e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.2388e6) {
                                    return PriceData(
                                        1.2653e6,
                                        0e18,
                                        630_249_409_724_609_181e18,
                                        1.2316e6,
                                        0e18,
                                        663_420_431_289_062_394e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.2653e6,
                                        0e18,
                                        630_249_409_724_609_181e18,
                                        1.2388e6,
                                        0e18,
                                        656_100_000_000_000_049e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.3101e6) {
                                if (price < 1.3003e6) {
                                    return PriceData(
                                        1.3101e6,
                                        0e18,
                                        590_490_000_000_000_030e18,
                                        1.2653e6,
                                        0e18,
                                        630_249_409_724_609_181e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.3101e6,
                                        0e18,
                                        590_490_000_000_000_030e18,
                                        1.3003e6,
                                        0e18,
                                        598_736_939_238_378_782e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.3368e6) {
                                    return PriceData(
                                        1.3748e6,
                                        0e18,
                                        540_360_087_662_636_788e18,
                                        1.3101e6,
                                        0e18,
                                        590_490_000_000_000_030e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.3748e6,
                                        0e18,
                                        540_360_087_662_636_788e18,
                                        1.3368e6,
                                        0e18,
                                        568_800_092_276_459_816e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    }
                } else {
                    if (price < 1.5924e6) {
                        if (price < 1.4722e6) {
                            if (price < 1.4145e6) {
                                if (price < 1.3875e6) {
                                    return PriceData(
                                        1.4145e6,
                                        0e18,
                                        513_342_083_279_504_885e18,
                                        1.3748e6,
                                        0e18,
                                        540_360_087_662_636_788e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.4145e6,
                                        0e18,
                                        513_342_083_279_504_885e18,
                                        1.3875e6,
                                        0e18,
                                        531_440_999_999_999_980e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.456e6) {
                                    return PriceData(
                                        1.4722e6,
                                        0e18,
                                        478_296_899_999_999_996e18,
                                        1.4145e6,
                                        0e18,
                                        513_342_083_279_504_885e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.4722e6,
                                        0e18,
                                        478_296_899_999_999_996e18,
                                        1.456e6,
                                        0e18,
                                        487_674_979_115_529_607e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.5448e6) {
                                if (price < 1.4994e6) {
                                    return PriceData(
                                        1.5448e6,
                                        0e18,
                                        440_126_668_651_765_444e18,
                                        1.4722e6,
                                        0e18,
                                        478_296_899_999_999_996e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.5448e6,
                                        0e18,
                                        440_126_668_651_765_444e18,
                                        1.4994e6,
                                        0e18,
                                        463_291_230_159_753_114e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.5651e6) {
                                    return PriceData(
                                        1.5924e6,
                                        0e18,
                                        418_120_335_219_177_149e18,
                                        1.5448e6,
                                        0e18,
                                        440_126_668_651_765_444e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.5924e6,
                                        0e18,
                                        418_120_335_219_177_149e18,
                                        1.5651e6,
                                        0e18,
                                        430_467_210_000_000_016e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 1.7499e6) {
                            if (price < 1.6676e6) {
                                if (price < 1.6424e6) {
                                    return PriceData(
                                        1.6676e6,
                                        0e18,
                                        387_420_489_000_000_015e18,
                                        1.5924e6,
                                        0e18,
                                        418_120_335_219_177_149e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.6676e6,
                                        0e18,
                                        387_420_489_000_000_015e18,
                                        1.6424e6,
                                        0e18,
                                        397_214_318_458_218_211e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.6948e6) {
                                    return PriceData(
                                        1.7499e6,
                                        0e18,
                                        358_485_922_408_541_867e18,
                                        1.6676e6,
                                        0e18,
                                        387_420_489_000_000_015e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.7499e6,
                                        0e18,
                                        358_485_922_408_541_867e18,
                                        1.6948e6,
                                        0e18,
                                        377_353_602_535_307_320e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.8078e6) {
                                if (price < 1.7808e6) {
                                    return PriceData(
                                        1.8078e6,
                                        0e18,
                                        340_561_626_288_114_794e18,
                                        1.7499e6,
                                        0e18,
                                        358_485_922_408_541_867e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.8078e6,
                                        0e18,
                                        340_561_626_288_114_794e18,
                                        1.7808e6,
                                        0e18,
                                        348_678_440_100_000_033e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.8687e6,
                                    0e18,
                                    323_533_544_973_709_067e18,
                                    1.8078e6,
                                    0e18,
                                    340_561_626_288_114_794e18,
                                    1e18
                                );
                            }
                        }
                    }
                }
            } else {
                if (price < 2.6905e6) {
                    if (price < 2.2254e6) {
                        if (price < 2.046e6) {
                            if (price < 1.9328e6) {
                                if (price < 1.9064e6) {
                                    return PriceData(
                                        1.9328e6,
                                        0e18,
                                        307_356_867_725_023_611e18,
                                        1.8687e6,
                                        0e18,
                                        323_533_544_973_709_067e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.9328e6,
                                        0e18,
                                        307_356_867_725_023_611e18,
                                        1.9064e6,
                                        0e18,
                                        313_810_596_089_999_996e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 2.0003e6) {
                                    return PriceData(
                                        2.046e6,
                                        0e18,
                                        0.282429536481000023e18,
                                        1.9328e6,
                                        0e18,
                                        0.307356867725023611e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        2.046e6,
                                        0e18,
                                        282_429_536_481_000_023e18,
                                        2.0003e6,
                                        0e18,
                                        291_989_024_338_772_393e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 2.1464e6) {
                                if (price < 2.0714e6) {
                                    return PriceData(
                                        2.1464e6,
                                        0e18,
                                        263_520_094_465_742_052e18,
                                        2.046e6,
                                        0e18,
                                        282_429_536_481_000_023e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        2.1464e6,
                                        0e18,
                                        263_520_094_465_742_052e18,
                                        2.0714e6,
                                        0e18,
                                        277_389_573_121_833_787e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 2.2015e6) {
                                    return PriceData(
                                        2.2254e6,
                                        0e18,
                                        250_344_089_742_454_930e18,
                                        2.1464e6,
                                        0e18,
                                        263_520_094_465_742_052e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        2.2254e6,
                                        0e18,
                                        250_344_089_742_454_930e18,
                                        2.2015e6,
                                        0e18,
                                        254_186_582_832_900_011e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 2.4893e6) {
                            if (price < 2.3748e6) {
                                if (price < 2.3087e6) {
                                    return PriceData(
                                        2.3748e6,
                                        0e18,
                                        228_767_924_549_610_027e18,
                                        2.2254e6,
                                        0e18,
                                        250_344_089_742_454_930e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        2.3748e6,
                                        0e18,
                                        228_767_924_549_610_027e18,
                                        2.3087e6,
                                        0e18,
                                        237_826_885_255_332_165e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 2.3966e6) {
                                    return PriceData(
                                        2.4893e6,
                                        0e18,
                                        214_638_763_942_937_242e18,
                                        2.3748e6,
                                        0e18,
                                        228_767_924_549_610_027e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        2.4893e6,
                                        0e18,
                                        214_638_763_942_937_242e18,
                                        2.3966e6,
                                        0e18,
                                        225_935_540_992_565_540e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 2.5872e6) {
                                if (price < 2.5683e6) {
                                    return PriceData(
                                        2.5872e6,
                                        0e18,
                                        203_906_825_745_790_394e18,
                                        2.4893e6,
                                        0e18,
                                        214_638_763_942_937_242e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        2.5872e6,
                                        0e18,
                                        203_906_825_745_790_394e18,
                                        2.5683e6,
                                        0e18,
                                        205_891_132_094_649_041e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    2.6905e6,
                                    0e18,
                                    193_711_484_458_500_834e18,
                                    2.5872e6,
                                    0e18,
                                    203_906_825_745_790_394e18,
                                    1e18
                                );
                            }
                        }
                    }
                } else {
                    if (price < 3.3001e6) {
                        if (price < 3.0261e6) {
                            if (price < 2.7995e6) {
                                if (price < 2.7845e6) {
                                    return PriceData(
                                        2.7995e6,
                                        0e18,
                                        184_025_910_235_575_779e18,
                                        2.6905e6,
                                        0e18,
                                        193_711_484_458_500_834e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        2.7995e6,
                                        0e18,
                                        184_025_910_235_575_779e18,
                                        2.7845e6,
                                        0e18,
                                        185_302_018_885_184_143e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 2.9146e6) {
                                    return PriceData(
                                        3.0261e6,
                                        0e18,
                                        166_771_816_996_665_739e18,
                                        2.7995e6,
                                        0e18,
                                        184_025_910_235_575_779e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        3.0261e6,
                                        0e18,
                                        166_771_816_996_665_739e18,
                                        2.9146e6,
                                        0e18,
                                        174_824_614_723_796_969e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 3.1645e6) {
                                if (price < 3.0362e6) {
                                    return PriceData(
                                        3.1645e6,
                                        0e18,
                                        157_779_214_788_226_770e18,
                                        3.0261e6,
                                        0e18,
                                        166_771_816_996_665_739e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        3.1645e6,
                                        0e18,
                                        157_779_214_788_226_770e18,
                                        3.0362e6,
                                        0e18,
                                        166_083_383_987_607_124e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 3.2964e6) {
                                    return PriceData(
                                        3.3001e6,
                                        0e18,
                                        149_890_254_048_815_411e18,
                                        3.1645e6,
                                        0e18,
                                        157_779_214_788_226_770e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        3.3001e6,
                                        0e18,
                                        149_890_254_048_815_411e18,
                                        3.2964e6,
                                        0e18,
                                        150_094_635_296_999_155e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 3.7541e6) {
                            if (price < 3.5945e6) {
                                if (price < 3.4433e6) {
                                    return PriceData(
                                        3.5945e6,
                                        0e18,
                                        135_275_954_279_055_877e18,
                                        3.3001e6,
                                        0e18,
                                        149_890_254_048_815_411e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        3.5945e6,
                                        0e18,
                                        135_275_954_279_055_877e18,
                                        3.4433e6,
                                        0e18,
                                        142_395_741_346_374_623e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 3.5987e6) {
                                    return PriceData(
                                        3.7541e6,
                                        0e18,
                                        128_512_156_565_103_091e18,
                                        3.5945e6,
                                        0e18,
                                        135_275_954_279_055_877e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        3.7541e6,
                                        0e18,
                                        128_512_156_565_103_091e18,
                                        3.5987e6,
                                        0e18,
                                        135_085_171_767_299_243e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 9.9223e6) {
                                if (price < 3.937e6) {
                                    return PriceData(
                                        9.9223e6,
                                        0e18,
                                        449_999_999_999_999_979e18,
                                        3.7541e6,
                                        0e18,
                                        128_512_156_565_103_091e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        9.9223e6,
                                        0e18,
                                        449_999_999_999_999_979e18,
                                        3.937e6,
                                        0e18,
                                        121_576_654_590_569_315e18,
                                        1e18
                                    );
                                }
                            } else {
                                revert("LUT: Invalid price");
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * @notice Returns the estimated range of reserve ratios for a given price,
     * assuming the pool liquidity remains constant.
     * Needed to calculate the amounts of assets to swap in a well for Beanstalk to return to peg.
     * Used in `calcReserveAtRatioSwap` function in the stableswap well function.
     */
    function getRatiosFromPriceSwap(uint256 price) external pure returns (PriceData memory) {
        if (price < 0.9837e6) {
            if (price < 0.7657e6) {
                if (price < 0.6853e6) {
                    if (price < 0.6456e6) {
                        if (price < 0.5892e6) {
                            if (price < 0.5536e6) {
                                if (price < 0.0104e6) {
                                    revert("LUT: Invalid price");
                                } else {
                                    return PriceData(
                                        0.5536e6,
                                        159_999_999_999_999_986e18,
                                        545_614_743_365_999_923e18,
                                        0.0104e6,
                                        627_199_835_701_845_745e18,
                                        301_704_303_299_995_369e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.5712e6) {
                                    return PriceData(
                                        0.5892e6,
                                        154_000_000_000_000_009e18,
                                        579_889_286_297_999_932e18,
                                        0.5536e6,
                                        159_999_999_999_999_986e18,
                                        545_614_743_365_999_923e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.5892e6,
                                        154_000_000_000_000_009e18,
                                        579_889_286_297_999_932e18,
                                        0.5712e6,
                                        156_999_999_999_999_997e18,
                                        562_484_780_749_999_921e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.6264e6) {
                                if (price < 0.6076e6) {
                                    return PriceData(
                                        0.6264e6,
                                        148_000_000_000_000_005e18,
                                        616_348_759_373_999_889e18,
                                        0.5892e6,
                                        154_000_000_000_000_009e18,
                                        579_889_286_297_999_932e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.6264e6,
                                        148_000_000_000_000_005e18,
                                        616_348_759_373_999_889e18,
                                        0.6076e6,
                                        150_999_999_999_999_993e18,
                                        597_839_994_250_999_858e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.6418e6) {
                                    return PriceData(
                                        0.6456e6,
                                        144_999_999_999_999_989e18,
                                        635_427_613_953_999_981e18,
                                        0.6264e6,
                                        148_000_000_000_000_005e18,
                                        616_348_759_373_999_889e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.6456e6,
                                        144_999_999_999_999_989e18,
                                        635_427_613_953_999_981e18,
                                        0.6418e6,
                                        145_600_999_296_581_034e18,
                                        631_633_461_631_000_017e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.6652e6) {
                            if (price < 0.6548e6) {
                                if (price < 0.6482e6) {
                                    return PriceData(
                                        0.6548e6,
                                        143_600_999_296_581_041e18,
                                        644_598_199_151_000_104e18,
                                        0.6456e6,
                                        144_999_999_999_999_989e18,
                                        635_427_613_953_999_981e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.6548e6,
                                        143_600_999_296_581_041e18,
                                        644_598_199_151_000_104e18,
                                        0.6482e6,
                                        144_600_999_296_581_037e18,
                                        638_083_385_911_000_032e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.6613e6) {
                                    return PriceData(
                                        0.6652e6,
                                        142_000_000_000_000_000e18,
                                        655_088_837_188_999_989e18,
                                        0.6548e6,
                                        143_600_999_296_581_041e18,
                                        644_598_199_151_000_104e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.6652e6,
                                        142_000_000_000_000_000e18,
                                        655_088_837_188_999_989e18,
                                        0.6613e6,
                                        142_600_999_296_581_045e18,
                                        651_178_365_231_000_060e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.6746e6) {
                                if (price < 0.6679e6) {
                                    return PriceData(
                                        0.6746e6,
                                        140_600_999_296_581_052e18,
                                        664_536_634_765_000_046e18,
                                        0.6652e6,
                                        142_000_000_000_000_000e18,
                                        655_088_837_188_999_989e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.6746e6,
                                        140_600_999_296_581_052e18,
                                        664_536_634_765_000_046e18,
                                        0.6679e6,
                                        141_600_999_296_581_049e18,
                                        657_824_352_616_000_123e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.6813e6) {
                                    return PriceData(
                                        0.6853e6,
                                        139_000_000_000_000_012e18,
                                        675_345_038_118_000_013e18,
                                        0.6746e6,
                                        140_600_999_296_581_052e18,
                                        664_536_634_765_000_046e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.6853e6,
                                        139_000_000_000_000_012e18,
                                        675_345_038_118_000_013e18,
                                        0.6813e6,
                                        139_600_999_296_581_056e18,
                                        671_315_690_563_000_076e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    }
                } else {
                    if (price < 0.7267e6) {
                        if (price < 0.7058e6) {
                            if (price < 0.6948e6) {
                                if (price < 0.688e6) {
                                    return PriceData(
                                        0.6948e6,
                                        137_600_999_296_581_037e18,
                                        685_076_068_526_999_994e18,
                                        0.6853e6,
                                        139_000_000_000_000_012e18,
                                        675_345_038_118_000_013e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.6948e6,
                                        137_600_999_296_581_037e18,
                                        685_076_068_526_999_994e18,
                                        0.688e6,
                                        138_600_999_296_581_033e18,
                                        678_162_004_775_999_991e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.7017e6) {
                                    return PriceData(
                                        0.7058e6,
                                        135_999_999_999_999_996e18,
                                        696_209_253_362_999_968e18,
                                        0.6948e6,
                                        137_600_999_296_581_037e18,
                                        685_076_068_526_999_994e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7058e6,
                                        135_999_999_999_999_996e18,
                                        696_209_253_362_999_968e18,
                                        0.7017e6,
                                        136_600_999_296_581_041e18,
                                        692_058_379_796_999_917e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.7155e6) {
                                if (price < 0.7086e6) {
                                    return PriceData(
                                        0.7155e6,
                                        134_600_999_296_581_048e18,
                                        706_229_774_288_999_996e18,
                                        0.7058e6,
                                        135_999_999_999_999_996e18,
                                        696_209_253_362_999_968e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7155e6,
                                        134_600_999_296_581_048e18,
                                        706_229_774_288_999_996e18,
                                        0.7086e6,
                                        135_600_999_296_581_045e18,
                                        699_109_443_950_999_980e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.7225e6) {
                                    return PriceData(
                                        0.7267e6,
                                        133_000_000_000_000_007e18,
                                        717_695_061_066_999_981e18,
                                        0.7155e6,
                                        134_600_999_296_581_048e18,
                                        706_229_774_288_999_996e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7267e6,
                                        133_000_000_000_000_007e18,
                                        717_695_061_066_999_981e18,
                                        0.7225e6,
                                        133_600_999_296_581_052e18,
                                        713_419_892_621_999_983e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.7482e6) {
                            if (price < 0.7367e6) {
                                if (price < 0.7296e6) {
                                    return PriceData(
                                        0.7367e6,
                                        131_600_999_296_581_033e18,
                                        728_011_626_732_999_961e18,
                                        0.7267e6,
                                        133_000_000_000_000_007e18,
                                        717_695_061_066_999_981e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7367e6,
                                        131_600_999_296_581_033e18,
                                        728_011_626_732_999_961e18,
                                        0.7296e6,
                                        132_600_999_296_581_056e18,
                                        720_680_329_877_999_918e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.7439e6) {
                                    return PriceData(
                                        0.7482e6,
                                        129_999_999_999_999_992e18,
                                        739_816_712_606_999_965e18,
                                        0.7367e6,
                                        131_600_999_296_581_033e18,
                                        728_011_626_732_999_961e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7482e6,
                                        129_999_999_999_999_992e18,
                                        739_816_712_606_999_965e18,
                                        0.7439e6,
                                        130_600_999_296_581_037e18,
                                        735_414_334_273_999_920e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.7584e6) {
                                if (price < 0.7511e6) {
                                    return PriceData(
                                        0.7584e6,
                                        128_600_999_296_581_044e18,
                                        750_436_241_990_999_850e18,
                                        0.7482e6,
                                        129_999_999_999_999_992e18,
                                        739_816_712_606_999_965e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7584e6,
                                        128_600_999_296_581_044e18,
                                        750_436_241_990_999_850e18,
                                        0.7511e6,
                                        129_600_999_296_581_040e18,
                                        742_889_014_688_999_846e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.7657e6,
                                    127_600_999_296_581_048e18,
                                    758_056_602_771_999_862e18,
                                    0.7584e6,
                                    128_600_999_296_581_044e18,
                                    750_436_241_990_999_850e18,
                                    1e18
                                );
                            }
                        }
                    }
                }
            } else {
                if (price < 0.8591e6) {
                    if (price < 0.8111e6) {
                        if (price < 0.7881e6) {
                            if (price < 0.7731e6) {
                                if (price < 0.7701e6) {
                                    return PriceData(
                                        0.7731e6,
                                        126_600_999_296_581_052e18,
                                        765_750_696_993_999_871e18,
                                        0.7657e6,
                                        127_600_999_296_581_048e18,
                                        758_056_602_771_999_862e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7731e6,
                                        126_600_999_296_581_052e18,
                                        765_750_696_993_999_871e18,
                                        0.7701e6,
                                        127_000_000_000_000_003e18,
                                        762_589_283_900_000_049e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.7806e6) {
                                    return PriceData(
                                        0.7881e6,
                                        124_600_999_296_581_059e18,
                                        781_362_557_425_999_864e18,
                                        0.7731e6,
                                        126_600_999_296_581_052e18,
                                        765_750_696_993_999_871e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7881e6,
                                        124_600_999_296_581_059e18,
                                        781_362_557_425_999_864e18,
                                        0.7806e6,
                                        125_600_999_296_581_055e18,
                                        773_519_138_809_999_964e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.7957e6) {
                                if (price < 0.7927e6) {
                                    return PriceData(
                                        0.7957e6,
                                        123_600_999_296_581_036e18,
                                        789_281_597_997_999_894e18,
                                        0.7881e6,
                                        124_600_999_296_581_059e18,
                                        781_362_557_425_999_864e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.7957e6,
                                        123_600_999_296_581_036e18,
                                        789_281_597_997_999_894e18,
                                        0.7927e6,
                                        123_999_999_999_999_988e18,
                                        786_028_848_437_000_042e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.8034e6) {
                                    return PriceData(
                                        0.8111e6,
                                        121_600_999_296_581_044e18,
                                        805_349_211_052_999_895e18,
                                        0.7957e6,
                                        123_600_999_296_581_036e18,
                                        789_281_597_997_999_894e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.8111e6,
                                        121_600_999_296_581_044e18,
                                        805_349_211_052_999_895e18,
                                        0.8034e6,
                                        122_600_999_296_581_040e18,
                                        797_276_922_569_999_826e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.8348e6) {
                            if (price < 0.8189e6) {
                                if (price < 0.8158e6) {
                                    return PriceData(
                                        0.8189e6,
                                        120_600_999_296_581_047e18,
                                        813_499_162_245_999_760e18,
                                        0.8111e6,
                                        121_600_999_296_581_044e18,
                                        805_349_211_052_999_895e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.8189e6,
                                        120_600_999_296_581_047e18,
                                        813_499_162_245_999_760e18,
                                        0.8158e6,
                                        120_999_999_999_999_999e18,
                                        810_152_674_566_000_114e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.8268e6) {
                                    return PriceData(
                                        0.8348e6,
                                        118_600_999_296_581_042e18,
                                        830_034_948_846_999_811e18,
                                        0.8189e6,
                                        120_600_999_296_581_047e18,
                                        813_499_162_245_999_760e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.8348e6,
                                        118_600_999_296_581_042e18,
                                        830_034_948_846_999_811e18,
                                        0.8268e6,
                                        119_600_999_296_581_051e18,
                                        821_727_494_902_999_775e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.8428e6) {
                                if (price < 0.8395e6) {
                                    return PriceData(
                                        0.8428e6,
                                        117_600_999_296_581_045e18,
                                        838_422_286_131_999_841e18,
                                        0.8348e6,
                                        118_600_999_296_581_042e18,
                                        830_034_948_846_999_811e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.8428e6,
                                        117_600_999_296_581_045e18,
                                        838_422_286_131_999_841e18,
                                        0.8395e6,
                                        117_999_999_999_999_997e18,
                                        834_979_450_092_000_118e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.8509e6) {
                                    return PriceData(
                                        0.8591e6,
                                        115_600_999_296_581_039e18,
                                        855_439_777_442_999_782e18,
                                        0.8428e6,
                                        117_600_999_296_581_045e18,
                                        838_422_286_131_999_841e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.8591e6,
                                        115_600_999_296_581_039e18,
                                        855_439_777_442_999_782e18,
                                        0.8509e6,
                                        116_600_999_296_581_049e18,
                                        846_890_292_257_999_745e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    }
                } else {
                    if (price < 0.9101e6) {
                        if (price < 0.8842e6) {
                            if (price < 0.8674e6) {
                                if (price < 0.864e6) {
                                    return PriceData(
                                        0.8674e6,
                                        114_600_999_296_581_043e18,
                                        864_071_577_944_999_841e18,
                                        0.8591e6,
                                        115_600_999_296_581_039e18,
                                        855_439_777_442_999_782e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.8674e6,
                                        114_600_999_296_581_043e18,
                                        864_071_577_944_999_841e18,
                                        0.864e6,
                                        114_999_999_999_999_995e18,
                                        860_529_537_869_000_136e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.8757e6) {
                                    return PriceData(
                                        0.8842e6,
                                        112_600_999_296_581_051e18,
                                        881_585_608_519_999_884e18,
                                        0.8674e6,
                                        114_600_999_296_581_043e18,
                                        864_071_577_944_999_841e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.8842e6,
                                        112_600_999_296_581_051e18,
                                        881_585_608_519_999_884e18,
                                        0.8757e6,
                                        113_600_999_296_581_047e18,
                                        872_786_557_449_999_864e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.8927e6) {
                                if (price < 0.8893e6) {
                                    return PriceData(
                                        0.8927e6,
                                        111_600_999_296_581_041e18,
                                        890_469_654_111_999_903e18,
                                        0.8842e6,
                                        112_600_999_296_581_051e18,
                                        881_585_608_519_999_884e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.8927e6,
                                        111_600_999_296_581_041e18,
                                        890_469_654_111_999_903e18,
                                        0.8893e6,
                                        112_000_000_000_000_006e18,
                                        886_825_266_904_000_064e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.9014e6) {
                                    return PriceData(
                                        0.9101e6,
                                        109_600_999_296_581_049e18,
                                        908_496_582_238_999_955e18,
                                        0.8927e6,
                                        111_600_999_296_581_041e18,
                                        890_469_654_111_999_903e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.9101e6,
                                        109_600_999_296_581_049e18,
                                        908_496_582_238_999_955e18,
                                        0.9014e6,
                                        110_600_999_296_581_045e18,
                                        899_439_649_160_999_875e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.937e6) {
                            if (price < 0.919e6) {
                                if (price < 0.9154e6) {
                                    return PriceData(
                                        0.919e6,
                                        108_600_999_296_581_052e18,
                                        917_641_477_296_999_901e18,
                                        0.9101e6,
                                        109_600_999_296_581_049e18,
                                        908_496_582_238_999_955e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.919e6,
                                        108_600_999_296_581_052e18,
                                        917_641_477_296_999_901e18,
                                        0.9154e6,
                                        109_000_000_000_000_004e18,
                                        913_891_264_499_999_987e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.9279e6) {
                                    return PriceData(
                                        0.937e6,
                                        106_600_999_296_581_047e18,
                                        936_199_437_051_999_863e18,
                                        0.919e6,
                                        108_600_999_296_581_052e18,
                                        917_641_477_296_999_901e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.937e6,
                                        106_600_999_296_581_047e18,
                                        936_199_437_051_999_863e18,
                                        0.9279e6,
                                        107_600_999_296_581_043e18,
                                        926_875_395_482_999_811e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.9706e6) {
                                if (price < 0.9425e6) {
                                    return PriceData(
                                        0.9706e6,
                                        103_000_000_000_000_000e18,
                                        970_446_402_236_000_094e18,
                                        0.937e6,
                                        106_600_999_296_581_047e18,
                                        936_199_437_051_999_863e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.9706e6,
                                        103_000_000_000_000_000e18,
                                        970_446_402_236_000_094e18,
                                        0.9425e6,
                                        106_000_000_000_000_002e18,
                                        941_754_836_243_000_007e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.9837e6,
                                    101_657_469_802_110_314e18,
                                    983_823_407_046_999_249e18,
                                    0.9706e6,
                                    103_000_000_000_000_000e18,
                                    970_446_402_236_000_094e18,
                                    1e18
                                );
                            }
                        }
                    }
                }
            }
        } else {
            if (price < 1.2781e6) {
                if (price < 1.1479e6) {
                    if (price < 1.0834e6) {
                        if (price < 1.0522e6) {
                            if (price < 1.042e6) {
                                if (price < 1.0137e6) {
                                    return PriceData(
                                        1.042e6,
                                        959_393_930_406_635_507e18,
                                        104_163_346_163_100_008e18,
                                        0.9837e6,
                                        101_657_469_802_110_314e18,
                                        983_823_407_046_999_249e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.042e6,
                                        959_393_930_406_635_507e18,
                                        104_163_346_163_100_008e18,
                                        1.0137e6,
                                        986_536_714_103_430_341e18,
                                        101_382_340_704_699_913e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.0442e6) {
                                    return PriceData(
                                        1.0522e6,
                                        949_844_925_094_088_539e18,
                                        105_163_346_163_100_004e18,
                                        1.042e6,
                                        959_393_930_406_635_507e18,
                                        104_163_346_163_100_008e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.0522e6,
                                        949_844_925_094_088_539e18,
                                        105_163_346_163_100_004e18,
                                        1.0442e6,
                                        957_380_872_867_950_333e18,
                                        104_382_340_704_699_915e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.0729e6) {
                                if (price < 1.0626e6) {
                                    return PriceData(
                                        1.0729e6,
                                        931_024_660_370_625_864e18,
                                        107_163_346_163_100_010e18,
                                        1.0522e6,
                                        949_844_925_094_088_539e18,
                                        105_163_346_163_100_004e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.0729e6,
                                        931_024_660_370_625_864e18,
                                        107_163_346_163_100_010e18,
                                        1.0626e6,
                                        940_388_903_170_712_077e18,
                                        106_163_346_163_100_000e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.0752e6) {
                                    return PriceData(
                                        1.0834e6,
                                        921_751_036_591_489_341e18,
                                        108_163_346_163_100_006e18,
                                        1.0729e6,
                                        931_024_660_370_625_864e18,
                                        107_163_346_163_100_010e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.0834e6,
                                        921_751_036_591_489_341e18,
                                        108_163_346_163_100_006e18,
                                        1.0752e6,
                                        929_070_940_571_911_522e18,
                                        107_382_340_704_699_931e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 1.1153e6) {
                            if (price < 1.1046e6) {
                                if (price < 1.094e6) {
                                    return PriceData(
                                        1.1046e6,
                                        903_471_213_736_046_924e18,
                                        110_163_346_163_099_998e18,
                                        1.0834e6,
                                        921_751_036_591_489_341e18,
                                        108_163_346_163_100_006e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.1046e6,
                                        903_471_213_736_046_924e18,
                                        110_163_346_163_099_998e18,
                                        1.094e6,
                                        912_566_913_749_610_422e18,
                                        109_163_346_163_100_002e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.1069e6) {
                                    return PriceData(
                                        1.1153e6,
                                        894_462_896_467_921_655e18,
                                        111_163_346_163_100_008e18,
                                        1.1046e6,
                                        903_471_213_736_046_924e18,
                                        110_163_346_163_099_998e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.1153e6,
                                        894_462_896_467_921_655e18,
                                        111_163_346_163_100_008e18,
                                        1.1069e6,
                                        901_574_605_299_420_214e18,
                                        110_382_340_704_699_933e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.137e6) {
                                if (price < 1.1261e6) {
                                    return PriceData(
                                        1.137e6,
                                        876_704_428_898_610_466e18,
                                        113_163_346_163_100_000e18,
                                        1.1153e6,
                                        894_462_896_467_921_655e18,
                                        111_163_346_163_100_008e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.137e6,
                                        876_704_428_898_610_466e18,
                                        113_163_346_163_100_000e18,
                                        1.1261e6,
                                        885_540_958_029_582_579e18,
                                        112_163_346_163_100_004e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.1393e6) {
                                    return PriceData(
                                        1.1479e6,
                                        867_952_372_252_030_623e18,
                                        114_163_346_163_100_010e18,
                                        1.137e6,
                                        876_704_428_898_610_466e18,
                                        113_163_346_163_100_000e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.1479e6,
                                        867_952_372_252_030_623e18,
                                        114_163_346_163_100_010e18,
                                        1.1393e6,
                                        874_862_932_837_460_311e18,
                                        113_382_340_704_699_935e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    }
                } else {
                    if (price < 1.2158e6) {
                        if (price < 1.1814e6) {
                            if (price < 1.1701e6) {
                                if (price < 1.159e6) {
                                    return PriceData(
                                        1.1701e6,
                                        850_698_082_981_724_339e18,
                                        116_163_346_163_100_003e18,
                                        1.1479e6,
                                        867_952_372_252_030_623e18,
                                        114_163_346_163_100_010e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.1701e6,
                                        850_698_082_981_724_339e18,
                                        116_163_346_163_100_003e18,
                                        1.159e6,
                                        859_283_882_348_396_836e18,
                                        115_163_346_163_100_006e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.1725e6) {
                                    return PriceData(
                                        1.1814e6,
                                        842_194_126_003_515_871e18,
                                        117_163_346_163_099_999e18,
                                        1.1701e6,
                                        850_698_082_981_724_339e18,
                                        116_163_346_163_100_003e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.1814e6,
                                        842_194_126_003_515_871e18,
                                        117_163_346_163_099_999e18,
                                        1.1725e6,
                                        848_909_895_863_161_958e18,
                                        116_382_340_704_699_937e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.2042e6) {
                                if (price < 1.1928e6) {
                                    return PriceData(
                                        1.2042e6,
                                        825_428_478_487_026_483e18,
                                        119_163_346_163_100_005e18,
                                        1.1814e6,
                                        842_194_126_003_515_871e18,
                                        117_163_346_163_099_999e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.2042e6,
                                        825_428_478_487_026_483e18,
                                        119_163_346_163_100_005e18,
                                        1.1928e6,
                                        833_771_189_909_386_858e18,
                                        118_163_346_163_100_008e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.2067e6) {
                                    return PriceData(
                                        1.2158e6,
                                        817_165_219_522_460_124e18,
                                        120_163_346_163_100_001e18,
                                        1.2042e6,
                                        825_428_478_487_026_483e18,
                                        119_163_346_163_100_005e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.2158e6,
                                        817_165_219_522_460_124e18,
                                        120_163_346_163_100_001e18,
                                        1.2067e6,
                                        823_691_964_726_974_573e18,
                                        119_382_340_704_699_926e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 1.2512e6) {
                            if (price < 1.2393e6) {
                                if (price < 1.2275e6) {
                                    return PriceData(
                                        1.2393e6,
                                        800_874_082_725_647_358e18,
                                        122_163_346_163_099_993e18,
                                        1.2158e6,
                                        817_165_219_522_460_124e18,
                                        120_163_346_163_100_001e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.2393e6,
                                        800_874_082_725_647_358e18,
                                        122_163_346_163_099_993e18,
                                        1.2275e6,
                                        808_980_663_561_772_026e18,
                                        121_163_346_163_099_997e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.2419e6) {
                                    return PriceData(
                                        1.2512e6,
                                        792_844_769_574_258_384e18,
                                        123_163_346_163_100_016e18,
                                        1.2393e6,
                                        800_874_082_725_647_358e18,
                                        122_163_346_163_099_993e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.2512e6,
                                        792_844_769_574_258_384e18,
                                        123_163_346_163_100_016e18,
                                        1.2419e6,
                                        799_187_750_396_588_808e18,
                                        122_382_340_704_699_941e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.2755e6) {
                                if (price < 1.2633e6) {
                                    return PriceData(
                                        1.2755e6,
                                        777_015_212_287_252_263e18,
                                        125_163_346_163_100_009e18,
                                        1.2512e6,
                                        792_844_769_574_258_384e18,
                                        123_163_346_163_100_016e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.2755e6,
                                        777_015_212_287_252_263e18,
                                        125_163_346_163_100_009e18,
                                        1.2633e6,
                                        784_892_036_020_190_803e18,
                                        124_163_346_163_100_013e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.2781e6,
                                    775_377_691_936_595_793e18,
                                    125_382_340_704_699_930e18,
                                    1.2755e6,
                                    777_015_212_287_252_263e18,
                                    125_163_346_163_100_009e18,
                                    1e18
                                );
                            }
                        }
                    }
                }
            } else {
                if (price < 1.4328e6) {
                    if (price < 1.3542e6) {
                        if (price < 1.3155e6) {
                            if (price < 1.3002e6) {
                                if (price < 1.2878e6) {
                                    return PriceData(
                                        1.3002e6,
                                        761_486_700_794_138_643e18,
                                        127_163_346_163_100_001e18,
                                        1.2781e6,
                                        775_377_691_936_595_793e18,
                                        125_382_340_704_699_930e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.3002e6,
                                        761_486_700_794_138_643e18,
                                        127_163_346_163_100_001e18,
                                        1.2878e6,
                                        769_213_645_913_148_350e18,
                                        126_163_346_163_100_005e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.3128e6) {
                                    return PriceData(
                                        1.3155e6,
                                        752_243_782_340_972_617e18,
                                        128_382_340_704_699_919e18,
                                        1.3002e6,
                                        761_486_700_794_138_643e18,
                                        127_163_346_163_100_001e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.3155e6,
                                        752_243_782_340_972_617e18,
                                        128_382_340_704_699_919e18,
                                        1.3128e6,
                                        753_833_756_269_910_991e18,
                                        128_163_346_163_099_997e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.3384e6) {
                                if (price < 1.3255e6) {
                                    return PriceData(
                                        1.3384e6,
                                        738_747_458_359_333_922e18,
                                        130_163_346_163_100_017e18,
                                        1.3155e6,
                                        752_243_782_340_972_617e18,
                                        128_382_340_704_699_919e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.3384e6,
                                        738_747_458_359_333_922e18,
                                        130_163_346_163_100_017e18,
                                        1.3255e6,
                                        746_254_206_247_018_816e18,
                                        129_163_346_163_099_994e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.3514e6) {
                                    return PriceData(
                                        1.3542e6,
                                        729_769_327_686_751_939e18,
                                        131_382_340_704_699_934e18,
                                        1.3384e6,
                                        738_747_458_359_333_922e18,
                                        130_163_346_163_100_017e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.3542e6,
                                        729_769_327_686_751_939e18,
                                        131_382_340_704_699_934e18,
                                        1.3514e6,
                                        731_312_933_164_060_298e18,
                                        131_163_346_163_100_013e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 1.3943e6) {
                            if (price < 1.3779e6) {
                                if (price < 1.3646e6) {
                                    return PriceData(
                                        1.3779e6,
                                        716_658_293_110_424_452e18,
                                        133_163_346_163_100_005e18,
                                        1.3542e6,
                                        729_769_327_686_751_939e18,
                                        131_382_340_704_699_934e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.3779e6,
                                        716_658_293_110_424_452e18,
                                        133_163_346_163_100_005e18,
                                        1.3646e6,
                                        723_950_063_371_948_465e18,
                                        132_163_346_163_100_009e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.3914e6) {
                                    return PriceData(
                                        1.3943e6,
                                        707_938_735_496_683_067e18,
                                        134_382_340_704_699_923e18,
                                        1.3779e6,
                                        716_658_293_110_424_452e18,
                                        133_163_346_163_100_005e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.3943e6,
                                        707_938_735_496_683_067e18,
                                        134_382_340_704_699_923e18,
                                        1.3914e6,
                                        709_437_077_218_432_531e18,
                                        134_163_346_163_100_002e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.4188e6) {
                                if (price < 1.405e6) {
                                    return PriceData(
                                        1.4188e6,
                                        695_204_177_438_428_696e18,
                                        136_163_346_163_099_994e18,
                                        1.3943e6,
                                        707_938_735_496_683_067e18,
                                        134_382_340_704_699_923e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.4188e6,
                                        695_204_177_438_428_696e18,
                                        136_163_346_163_099_994e18,
                                        1.405e6,
                                        702_285_880_571_853_430e18,
                                        135_163_346_163_099_998e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.4328e6,
                                    688_191_450_861_183_111e18,
                                    137_163_346_163_099_990e18,
                                    1.4188e6,
                                    695_204_177_438_428_696e18,
                                    136_163_346_163_099_994e18,
                                    1e18
                                );
                            }
                        }
                    }
                } else {
                    if (price < 1.5204e6) {
                        if (price < 1.4758e6) {
                            if (price < 1.4469e6) {
                                if (price < 1.4358e6) {
                                    return PriceData(
                                        1.4469e6,
                                        681_247_192_069_384_962e18,
                                        138_163_346_163_100_013e18,
                                        1.4328e6,
                                        688_191_450_861_183_111e18,
                                        137_163_346_163_099_990e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.4469e6,
                                        681_247_192_069_384_962e18,
                                        138_163_346_163_100_013e18,
                                        1.4358e6,
                                        686_737_328_931_840_165e18,
                                        137_382_340_704_699_938e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.4613e6) {
                                    return PriceData(
                                        1.4758e6,
                                        667_562_080_341_789_698e18,
                                        140_163_346_163_100_006e18,
                                        1.4469e6,
                                        681_247_192_069_384_962e18,
                                        138_163_346_163_100_013e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.4758e6,
                                        667_562_080_341_789_698e18,
                                        140_163_346_163_100_006e18,
                                        1.4613e6,
                                        674_370_899_916_144_494e18,
                                        139_163_346_163_100_010e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.4904e6) {
                                if (price < 1.4789e6) {
                                    return PriceData(
                                        1.4904e6,
                                        660_820_245_862_202_021e18,
                                        141_163_346_163_100_002e18,
                                        1.4758e6,
                                        667_562_080_341_789_698e18,
                                        140_163_346_163_100_006e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.4904e6,
                                        660_820_245_862_202_021e18,
                                        141_163_346_163_100_002e18,
                                        1.4789e6,
                                        666_151_184_017_568_179e18,
                                        140_382_340_704_699_927e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.5053e6) {
                                    return PriceData(
                                        1.5204e6,
                                        647_535_612_227_205_331e18,
                                        143_163_346_163_099_995e18,
                                        1.4904e6,
                                        660_820_245_862_202_021e18,
                                        141_163_346_163_100_002e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.5204e6,
                                        647_535_612_227_205_331e18,
                                        143_163_346_163_099_995e18,
                                        1.5053e6,
                                        654_144_915_081_340_263e18,
                                        142_163_346_163_099_998e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 1.6687e6) {
                            if (price < 1.5701e6) {
                                if (price < 1.5236e6) {
                                    return PriceData(
                                        1.5701e6,
                                        626_771_913_818_503_370e18,
                                        146_382_340_704_699_931e18,
                                        1.5204e6,
                                        647_535_612_227_205_331e18,
                                        143_163_346_163_099_995e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.5701e6,
                                        626_771_913_818_503_370e18,
                                        146_382_340_704_699_931e18,
                                        1.5236e6,
                                        646_166_987_566_021_192e18,
                                        143_382_340_704_699_942e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.6184e6) {
                                    return PriceData(
                                        1.6687e6,
                                        589_699_646_066_015_911e18,
                                        152_382_340_704_699_935e18,
                                        1.5701e6,
                                        626_771_913_818_503_370e18,
                                        146_382_340_704_699_931e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.6687e6,
                                        589_699_646_066_015_911e18,
                                        152_382_340_704_699_935e18,
                                        1.6184e6,
                                        607_953_518_109_393_449e18,
                                        149_382_340_704_699_920e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 9.8597e6) {
                                if (price < 1.7211e6) {
                                    return PriceData(
                                        9.8597e6,
                                        141_771_511_686_624_031e18,
                                        313_017_043_032_999_954e18,
                                        1.6687e6,
                                        589_699_646_066_015_911e18,
                                        152_382_340_704_699_935e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        9.8597e6,
                                        141_771_511_686_624_031e18,
                                        313_017_043_032_999_954e18,
                                        1.7211e6,
                                        571_998_357_018_457_696e18,
                                        155_382_340_704_699_924e18,
                                        1e18
                                    );
                                }
                            } else {
                                revert("LUT: Invalid price");
                            }
                        }
                    }
                }
            }
        }
    }
}
