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
        if (price < 1.006623e6) {
            if (price < 0.825934e6) {
                if (price < 0.741141e6) {
                    if (price < 0.412329e6) {
                        if (price < 0.268539e6) {
                            if (price < 0.211448e6) {
                                if (price < 0.001832e6) {
                                    revert("LUT: Invalid price");
                                } else {
                                    return PriceData(
                                        0.211448e6,
                                        0.0e18,
                                        0.077562793638189589e18,
                                        0.001832e6,
                                        0.0e18,
                                        0.000833333333333333e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.238695e6) {
                                    return PriceData(
                                        0.268539e6,
                                        0.0e18,
                                        0.100158566165017532e18,
                                        0.211448e6,
                                        0.0e18,
                                        0.077562793638189589e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.268539e6,
                                        0.0e18,
                                        0.100158566165017532e18,
                                        0.238695e6,
                                        0.0e18,
                                        0.088139538225215433e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.335863e6) {
                                if (price < 0.300961e6) {
                                    return PriceData(
                                        0.335863e6,
                                        0.0e18,
                                        0.129336991432099091e18,
                                        0.268539e6,
                                        0.0e18,
                                        0.100158566165017532e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.335863e6,
                                        0.0e18,
                                        0.129336991432099091e18,
                                        0.300961e6,
                                        0.0e18,
                                        0.113816552460247203e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.373071e6) {
                                    return PriceData(
                                        0.412329e6,
                                        0.0e18,
                                        0.167015743068309769e18,
                                        0.335863e6,
                                        0.0e18,
                                        0.129336991432099091e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.412329e6,
                                        0.0e18,
                                        0.167015743068309769e18,
                                        0.373071e6,
                                        0.0e18,
                                        0.146973853900112583e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.582463e6) {
                            if (price < 0.495602e6) {
                                if (price < 0.453302e6) {
                                    return PriceData(
                                        0.495602e6,
                                        0.0e18,
                                        0.215671155821681004e18,
                                        0.412329e6,
                                        0.0e18,
                                        0.167015743068309769e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.495602e6,
                                        0.0e18,
                                        0.215671155821681004e18,
                                        0.453302e6,
                                        0.0e18,
                                        0.189790617123079292e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.538801e6) {
                                    return PriceData(
                                        0.582463e6,
                                        0.0e18,
                                        0.278500976009402101e18,
                                        0.495602e6,
                                        0.0e18,
                                        0.215671155821681004e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.582463e6,
                                        0.0e18,
                                        0.278500976009402101e18,
                                        0.538801e6,
                                        0.0e18,
                                        0.245080858888273884e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.669604e6) {
                                if (price < 0.626181e6) {
                                    return PriceData(
                                        0.669604e6,
                                        0.0e18,
                                        0.359634524805529598e18,
                                        0.582463e6,
                                        0.0e18,
                                        0.278500976009402101e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.669604e6,
                                        0.0e18,
                                        0.359634524805529598e18,
                                        0.626181e6,
                                        0.0e18,
                                        0.316478381828866062e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.712465e6) {
                                    return PriceData(
                                        0.741141e6,
                                        0.0e18,
                                        0.445700403950951007e18,
                                        0.669604e6,
                                        0.0e18,
                                        0.359634524805529598e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.741141e6,
                                        0.0e18,
                                        0.445700403950951007e18,
                                        0.712465e6,
                                        0.0e18,
                                        0.408675596369920013e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    }
                } else {
                    if (price < 0.787158e6) {
                        if (price < 0.760974e6) {
                            if (price < 0.754382e6) {
                                if (price < 0.747771e6) {
                                    return PriceData(
                                        0.754382e6,
                                        0.0e18,
                                        0.464077888328770338e18,
                                        0.741141e6,
                                        0.0e18,
                                        0.445700403950951007e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.754382e6,
                                        0.0e18,
                                        0.464077888328770338e18,
                                        0.747771e6,
                                        0.0e18,
                                        0.454796330562194928e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.754612e6) {
                                    return PriceData(
                                        0.760974e6,
                                        0.0e18,
                                        0.473548865641602368e18,
                                        0.754382e6,
                                        0.0e18,
                                        0.464077888328770338e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.760974e6,
                                        0.0e18,
                                        0.473548865641602368e18,
                                        0.754612e6,
                                        0.0e18,
                                        0.464404086784000025e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.774102e6) {
                                if (price < 0.767548e6) {
                                    return PriceData(
                                        0.774102e6,
                                        0.0e18,
                                        0.49307462061807833e18,
                                        0.760974e6,
                                        0.0e18,
                                        0.473548865641602368e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.774102e6,
                                        0.0e18,
                                        0.49307462061807833e18,
                                        0.767548e6,
                                        0.0e18,
                                        0.483213128205716769e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.780639e6) {
                                    return PriceData(
                                        0.787158e6,
                                        0.0e18,
                                        0.513405477528194876e18,
                                        0.774102e6,
                                        0.0e18,
                                        0.49307462061807833e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.787158e6,
                                        0.0e18,
                                        0.513405477528194876e18,
                                        0.780639e6,
                                        0.0e18,
                                        0.503137367977630867e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.806614e6) {
                            if (price < 0.796011e6) {
                                if (price < 0.79366e6) {
                                    return PriceData(
                                        0.796011e6,
                                        0.0e18,
                                        0.527731916799999978e18,
                                        0.787158e6,
                                        0.0e18,
                                        0.513405477528194876e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.796011e6,
                                        0.0e18,
                                        0.527731916799999978e18,
                                        0.79366e6,
                                        0.0e18,
                                        0.523883140334892694e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.800145e6) {
                                    return PriceData(
                                        0.806614e6,
                                        0.0e18,
                                        0.545484319382437244e18,
                                        0.796011e6,
                                        0.0e18,
                                        0.527731916799999978e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.806614e6,
                                        0.0e18,
                                        0.545484319382437244e18,
                                        0.800145e6,
                                        0.0e18,
                                        0.534574632994788468e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.819507e6) {
                                if (price < 0.813068e6) {
                                    return PriceData(
                                        0.819507e6,
                                        0.0e18,
                                        0.567976175950059559e18,
                                        0.806614e6,
                                        0.0e18,
                                        0.545484319382437244e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.819507e6,
                                        0.0e18,
                                        0.567976175950059559e18,
                                        0.813068e6,
                                        0.0e18,
                                        0.55661665243105829e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.825934e6,
                                    0.0e18,
                                    0.579567526479652595e18,
                                    0.819507e6,
                                    0.0e18,
                                    0.567976175950059559e18,
                                    1e18
                                );
                            }
                        }
                    }
                }
            } else {
                if (price < 0.915208e6) {
                    if (price < 0.870637e6) {
                        if (price < 0.845143e6) {
                            if (price < 0.836765e6) {
                                if (price < 0.832347e6) {
                                    return PriceData(
                                        0.836765e6,
                                        0.0e18,
                                        0.599695360000000011e18,
                                        0.825934e6,
                                        0.0e18,
                                        0.579567526479652595e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.836765e6,
                                        0.0e18,
                                        0.599695360000000011e18,
                                        0.832347e6,
                                        0.0e18,
                                        0.591395435183319051e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.838751e6) {
                                    return PriceData(
                                        0.845143e6,
                                        0.0e18,
                                        0.615780336509078485e18,
                                        0.836765e6,
                                        0.0e18,
                                        0.599695360000000011e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.845143e6,
                                        0.0e18,
                                        0.615780336509078485e18,
                                        0.838751e6,
                                        0.0e18,
                                        0.60346472977889698e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.857902e6) {
                                if (price < 0.851526e6) {
                                    return PriceData(
                                        0.857902e6,
                                        0.0e18,
                                        0.641170696073592783e18,
                                        0.845143e6,
                                        0.0e18,
                                        0.615780336509078485e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.857902e6,
                                        0.0e18,
                                        0.641170696073592783e18,
                                        0.851526e6,
                                        0.0e18,
                                        0.628347282152120878e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.864272e6) {
                                    return PriceData(
                                        0.870637e6,
                                        0.0e18,
                                        0.667607971755094454e18,
                                        0.857902e6,
                                        0.0e18,
                                        0.641170696073592783e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.870637e6,
                                        0.0e18,
                                        0.667607971755094454e18,
                                        0.864272e6,
                                        0.0e18,
                                        0.654255812319992636e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.889721e6) {
                            if (price < 0.87711e6) {
                                if (price < 0.877e6) {
                                    return PriceData(
                                        0.87711e6,
                                        0.0e18,
                                        0.681471999999999967e18,
                                        0.870637e6,
                                        0.0e18,
                                        0.667607971755094454e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.87711e6,
                                        0.0e18,
                                        0.681471999999999967e18,
                                        0.877e6,
                                        0.0e18,
                                        0.681232624239892393e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.88336e6) {
                                    return PriceData(
                                        0.889721e6,
                                        0.0e18,
                                        0.709321766180645907e18,
                                        0.87711e6,
                                        0.0e18,
                                        0.681471999999999967e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.889721e6,
                                        0.0e18,
                                        0.709321766180645907e18,
                                        0.88336e6,
                                        0.0e18,
                                        0.695135330857033051e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.902453e6) {
                                if (price < 0.896084e6) {
                                    return PriceData(
                                        0.902453e6,
                                        0.0e18,
                                        0.738569102645403985e18,
                                        0.889721e6,
                                        0.0e18,
                                        0.709321766180645907e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.902453e6,
                                        0.0e18,
                                        0.738569102645403985e18,
                                        0.896084e6,
                                        0.0e18,
                                        0.723797720592495919e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.908826e6) {
                                    return PriceData(
                                        0.915208e6,
                                        0.0e18,
                                        0.769022389260104022e18,
                                        0.902453e6,
                                        0.0e18,
                                        0.738569102645403985e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.915208e6,
                                        0.0e18,
                                        0.769022389260104022e18,
                                        0.908826e6,
                                        0.0e18,
                                        0.753641941474902044e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    }
                } else {
                    if (price < 0.958167e6) {
                        if (price < 0.934425e6) {
                            if (price < 0.9216e6) {
                                if (price < 0.917411e6) {
                                    return PriceData(
                                        0.9216e6,
                                        0.0e18,
                                        0.784716723734800059e18,
                                        0.915208e6,
                                        0.0e18,
                                        0.769022389260104022e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.9216e6,
                                        0.0e18,
                                        0.784716723734800059e18,
                                        0.917411e6,
                                        0.0e18,
                                        0.774399999999999977e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.928005e6) {
                                    return PriceData(
                                        0.934425e6,
                                        0.0e18,
                                        0.81707280688754691e18,
                                        0.9216e6,
                                        0.0e18,
                                        0.784716723734800059e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.934425e6,
                                        0.0e18,
                                        0.81707280688754691e18,
                                        0.928005e6,
                                        0.0e18,
                                        0.800731350749795956e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.947318e6) {
                                if (price < 0.940861e6) {
                                    return PriceData(
                                        0.947318e6,
                                        0.0e18,
                                        0.8507630225817856e18,
                                        0.934425e6,
                                        0.0e18,
                                        0.81707280688754691e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.947318e6,
                                        0.0e18,
                                        0.8507630225817856e18,
                                        0.940861e6,
                                        0.0e18,
                                        0.833747762130149894e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.953797e6) {
                                    return PriceData(
                                        0.958167e6,
                                        0.0e18,
                                        0.880000000000000004e18,
                                        0.947318e6,
                                        0.0e18,
                                        0.8507630225817856e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.958167e6,
                                        0.0e18,
                                        0.880000000000000004e18,
                                        0.953797e6,
                                        0.0e18,
                                        0.868125533246720038e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.979988e6) {
                            if (price < 0.966831e6) {
                                if (price < 0.960301e6) {
                                    return PriceData(
                                        0.966831e6,
                                        0.0e18,
                                        0.903920796799999926e18,
                                        0.958167e6,
                                        0.0e18,
                                        0.880000000000000004e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.966831e6,
                                        0.0e18,
                                        0.903920796799999926e18,
                                        0.960301e6,
                                        0.0e18,
                                        0.885842380864000023e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.973393e6) {
                                    return PriceData(
                                        0.979988e6,
                                        0.0e18,
                                        0.941192000000000029e18,
                                        0.966831e6,
                                        0.0e18,
                                        0.903920796799999926e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.979988e6,
                                        0.0e18,
                                        0.941192000000000029e18,
                                        0.973393e6,
                                        0.0e18,
                                        0.922368159999999992e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.993288e6) {
                                if (price < 0.986618e6) {
                                    return PriceData(
                                        0.993288e6,
                                        0.0e18,
                                        0.980000000000000093e18,
                                        0.979988e6,
                                        0.0e18,
                                        0.941192000000000029e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.993288e6,
                                        0.0e18,
                                        0.980000000000000093e18,
                                        0.986618e6,
                                        0.0e18,
                                        0.960400000000000031e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.006623e6,
                                    0.0e18,
                                    1.020000000000000018e18,
                                    0.993288e6,
                                    0.0e18,
                                    0.980000000000000093e18,
                                    1e18
                                );
                            }
                        }
                    }
                }
            }
        } else {
            if (price < 1.214961e6) {
                if (price < 1.105774e6) {
                    if (price < 1.054473e6) {
                        if (price < 1.033615e6) {
                            if (price < 1.020013e6) {
                                if (price < 1.013294e6) {
                                    return PriceData(
                                        1.020013e6,
                                        0.0e18,
                                        1.061208000000000151e18,
                                        1.006623e6,
                                        0.0e18,
                                        1.020000000000000018e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.020013e6,
                                        0.0e18,
                                        1.061208000000000151e18,
                                        1.013294e6,
                                        0.0e18,
                                        1.040399999999999991e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.026785e6) {
                                    return PriceData(
                                        1.033615e6,
                                        0.0e18,
                                        1.104080803200000016e18,
                                        1.020013e6,
                                        0.0e18,
                                        1.061208000000000151e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.033615e6,
                                        0.0e18,
                                        1.104080803200000016e18,
                                        1.026785e6,
                                        0.0e18,
                                        1.082432159999999977e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.040503e6) {
                                if (price < 1.038588e6) {
                                    return PriceData(
                                        1.040503e6,
                                        0.0e18,
                                        1.12616241926400007e18,
                                        1.033615e6,
                                        0.0e18,
                                        1.104080803200000016e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.040503e6,
                                        0.0e18,
                                        1.12616241926400007e18,
                                        1.038588e6,
                                        0.0e18,
                                        1.120000000000000107e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.047454e6) {
                                    return PriceData(
                                        1.054473e6,
                                        0.0e18,
                                        1.171659381002265521e18,
                                        1.040503e6,
                                        0.0e18,
                                        1.12616241926400007e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.054473e6,
                                        0.0e18,
                                        1.171659381002265521e18,
                                        1.047454e6,
                                        0.0e18,
                                        1.14868566764928004e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 1.079216e6) {
                            if (price < 1.068722e6) {
                                if (price < 1.06156e6) {
                                    return PriceData(
                                        1.068722e6,
                                        0.0e18,
                                        1.218994419994757328e18,
                                        1.054473e6,
                                        0.0e18,
                                        1.171659381002265521e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.068722e6,
                                        0.0e18,
                                        1.218994419994757328e18,
                                        1.06156e6,
                                        0.0e18,
                                        1.195092568622310836e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.075962e6) {
                                    return PriceData(
                                        1.079216e6,
                                        0.0e18,
                                        1.254399999999999959e18,
                                        1.068722e6,
                                        0.0e18,
                                        1.218994419994757328e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.079216e6,
                                        0.0e18,
                                        1.254399999999999959e18,
                                        1.075962e6,
                                        0.0e18,
                                        1.243374308394652239e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.09069e6) {
                                if (price < 1.083283e6) {
                                    return PriceData(
                                        1.09069e6,
                                        0.0e18,
                                        1.293606630453796313e18,
                                        1.079216e6,
                                        0.0e18,
                                        1.254399999999999959e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.09069e6,
                                        0.0e18,
                                        1.293606630453796313e18,
                                        1.083283e6,
                                        0.0e18,
                                        1.268241794562545266e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.098185e6) {
                                    return PriceData(
                                        1.105774e6,
                                        0.0e18,
                                        1.345868338324129665e18,
                                        1.09069e6,
                                        0.0e18,
                                        1.293606630453796313e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.105774e6,
                                        0.0e18,
                                        1.345868338324129665e18,
                                        1.098185e6,
                                        0.0e18,
                                        1.319478763062872151e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    }
                } else {
                    if (price < 1.161877e6) {
                        if (price < 1.129145e6) {
                            if (price < 1.12125e6) {
                                if (price < 1.113461e6) {
                                    return PriceData(
                                        1.12125e6,
                                        0.0e18,
                                        1.400241419192424397e18,
                                        1.105774e6,
                                        0.0e18,
                                        1.345868338324129665e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.12125e6,
                                        0.0e18,
                                        1.400241419192424397e18,
                                        1.113461e6,
                                        0.0e18,
                                        1.372785705090612263e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.122574e6) {
                                    return PriceData(
                                        1.129145e6,
                                        0.0e18,
                                        1.428246247576273165e18,
                                        1.12125e6,
                                        0.0e18,
                                        1.400241419192424397e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.129145e6,
                                        0.0e18,
                                        1.428246247576273165e18,
                                        1.122574e6,
                                        0.0e18,
                                        1.404927999999999955e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.145271e6) {
                                if (price < 1.137151e6) {
                                    return PriceData(
                                        1.145271e6,
                                        0.0e18,
                                        1.485947395978354457e18,
                                        1.129145e6,
                                        0.0e18,
                                        1.428246247576273165e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.145271e6,
                                        0.0e18,
                                        1.485947395978354457e18,
                                        1.137151e6,
                                        0.0e18,
                                        1.456811172527798348e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.153512e6) {
                                    return PriceData(
                                        1.161877e6,
                                        0.0e18,
                                        1.545979670775879944e18,
                                        1.145271e6,
                                        0.0e18,
                                        1.485947395978354457e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.161877e6,
                                        0.0e18,
                                        1.545979670775879944e18,
                                        1.153512e6,
                                        0.0e18,
                                        1.515666343897921431e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 1.187769e6) {
                            if (price < 1.170371e6) {
                                if (price < 1.169444e6) {
                                    return PriceData(
                                        1.170371e6,
                                        0.0e18,
                                        1.576899264191397476e18,
                                        1.161877e6,
                                        0.0e18,
                                        1.545979670775879944e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.170371e6,
                                        0.0e18,
                                        1.576899264191397476e18,
                                        1.169444e6,
                                        0.0e18,
                                        1.573519359999999923e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.179e6) {
                                    return PriceData(
                                        1.187769e6,
                                        0.0e18,
                                        1.640605994464729989e18,
                                        1.170371e6,
                                        0.0e18,
                                        1.576899264191397476e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.187769e6,
                                        0.0e18,
                                        1.640605994464729989e18,
                                        1.179e6,
                                        0.0e18,
                                        1.608437249475225483e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.205744e6) {
                                if (price < 1.196681e6) {
                                    return PriceData(
                                        1.205744e6,
                                        0.0e18,
                                        1.706886476641104933e18,
                                        1.187769e6,
                                        0.0e18,
                                        1.640605994464729989e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.205744e6,
                                        0.0e18,
                                        1.706886476641104933e18,
                                        1.196681e6,
                                        0.0e18,
                                        1.673418114354024322e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.214961e6,
                                    0.0e18,
                                    1.741024206173927169e18,
                                    1.205744e6,
                                    0.0e18,
                                    1.706886476641104933e18,
                                    1e18
                                );
                            }
                        }
                    }
                }
            } else {
                if (price < 1.34048e6) {
                    if (price < 1.277347e6) {
                        if (price < 1.2436e6) {
                            if (price < 1.224339e6) {
                                if (price < 1.220705e6) {
                                    return PriceData(
                                        1.224339e6,
                                        0.0e18,
                                        1.775844690297405881e18,
                                        1.214961e6,
                                        0.0e18,
                                        1.741024206173927169e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.224339e6,
                                        0.0e18,
                                        1.775844690297405881e18,
                                        1.220705e6,
                                        0.0e18,
                                        1.762341683200000064e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.233883e6) {
                                    return PriceData(
                                        1.2436e6,
                                        0.0e18,
                                        1.847588815785421001e18,
                                        1.224339e6,
                                        0.0e18,
                                        1.775844690297405881e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.2436e6,
                                        0.0e18,
                                        1.847588815785421001e18,
                                        1.233883e6,
                                        0.0e18,
                                        1.811361584103353684e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.263572e6) {
                                if (price < 1.253494e6) {
                                    return PriceData(
                                        1.263572e6,
                                        0.0e18,
                                        1.92223140394315184e18,
                                        1.2436e6,
                                        0.0e18,
                                        1.847588815785421001e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.263572e6,
                                        0.0e18,
                                        1.92223140394315184e18,
                                        1.253494e6,
                                        0.0e18,
                                        1.884540592101129342e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.273838e6) {
                                    return PriceData(
                                        1.277347e6,
                                        0.0e18,
                                        1.973822685183999948e18,
                                        1.263572e6,
                                        0.0e18,
                                        1.92223140394315184e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.277347e6,
                                        0.0e18,
                                        1.973822685183999948e18,
                                        1.273838e6,
                                        0.0e18,
                                        1.960676032022014903e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 1.316927e6) {
                            if (price < 1.294966e6) {
                                if (price < 1.284301e6) {
                                    return PriceData(
                                        1.294966e6,
                                        0.0e18,
                                        2.039887343715704127e18,
                                        1.277347e6,
                                        0.0e18,
                                        1.973822685183999948e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.294966e6,
                                        0.0e18,
                                        2.039887343715704127e18,
                                        1.284301e6,
                                        0.0e18,
                                        1.999889552662455161e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.305839e6) {
                                    return PriceData(
                                        1.316927e6,
                                        0.0e18,
                                        2.122298792401818623e18,
                                        1.294966e6,
                                        0.0e18,
                                        2.039887343715704127e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.316927e6,
                                        0.0e18,
                                        2.122298792401818623e18,
                                        1.305839e6,
                                        0.0e18,
                                        2.080685090590018493e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.339776e6) {
                                if (price < 1.328238e6) {
                                    return PriceData(
                                        1.339776e6,
                                        0.0e18,
                                        2.208039663614852266e18,
                                        1.316927e6,
                                        0.0e18,
                                        2.122298792401818623e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.339776e6,
                                        0.0e18,
                                        2.208039663614852266e18,
                                        1.328238e6,
                                        0.0e18,
                                        2.164744768249855067e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.34048e6,
                                    0.0e18,
                                    2.210681407406080101e18,
                                    1.339776e6,
                                    0.0e18,
                                    2.208039663614852266e18,
                                    1e18
                                );
                            }
                        }
                    }
                } else {
                    if (price < 2.267916e6) {
                        if (price < 1.685433e6) {
                            if (price < 1.491386e6) {
                                if (price < 1.411358e6) {
                                    return PriceData(
                                        1.491386e6,
                                        0.0e18,
                                        2.773078757450186949e18,
                                        1.34048e6,
                                        0.0e18,
                                        2.210681407406080101e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.491386e6,
                                        0.0e18,
                                        2.773078757450186949e18,
                                        1.411358e6,
                                        0.0e18,
                                        2.475963176294809553e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.58215e6) {
                                    return PriceData(
                                        1.685433e6,
                                        0.0e18,
                                        3.478549993345514402e18,
                                        1.491386e6,
                                        0.0e18,
                                        2.773078757450186949e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.685433e6,
                                        0.0e18,
                                        3.478549993345514402e18,
                                        1.58215e6,
                                        0.0e18,
                                        3.105848208344209382e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.937842e6) {
                                if (price < 1.803243e6) {
                                    return PriceData(
                                        1.937842e6,
                                        0.0e18,
                                        4.363493111652613443e18,
                                        1.685433e6,
                                        0.0e18,
                                        3.478549993345514402e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.937842e6,
                                        0.0e18,
                                        4.363493111652613443e18,
                                        1.803243e6,
                                        0.0e18,
                                        3.89597599254697613e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 2.091777e6) {
                                    return PriceData(
                                        2.267916e6,
                                        0.0e18,
                                        5.473565759257038366e18,
                                        1.937842e6,
                                        0.0e18,
                                        4.363493111652613443e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        2.267916e6,
                                        0.0e18,
                                        5.473565759257038366e18,
                                        2.091777e6,
                                        0.0e18,
                                        4.887112285050926097e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 3.265419e6) {
                            if (price < 2.700115e6) {
                                if (price < 2.469485e6) {
                                    return PriceData(
                                        2.700115e6,
                                        0.0e18,
                                        6.866040888412029197e18,
                                        2.267916e6,
                                        0.0e18,
                                        5.473565759257038366e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        2.700115e6,
                                        0.0e18,
                                        6.866040888412029197e18,
                                        2.469485e6,
                                        0.0e18,
                                        6.130393650367882863e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 2.963895e6) {
                                    return PriceData(
                                        3.265419e6,
                                        0.0e18,
                                        8.612761690424049377e18,
                                        2.700115e6,
                                        0.0e18,
                                        6.866040888412029197e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        3.265419e6,
                                        0.0e18,
                                        8.612761690424049377e18,
                                        2.963895e6,
                                        0.0e18,
                                        7.689965795021471706e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 10.370891e6) {
                                if (price < 3.60986e6) {
                                    return PriceData(
                                        10.370891e6,
                                        0.0e18,
                                        28.000000000000003553e18,
                                        3.265419e6,
                                        0.0e18,
                                        8.612761690424049377e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        10.370891e6,
                                        0.0e18,
                                        28.000000000000003553e18,
                                        3.60986e6,
                                        0.0e18,
                                        9.646293093274934449e18,
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
        if (price < 0.993344e6) {
            if (price < 0.834426e6) {
                if (price < 0.718073e6) {
                    if (price < 0.391201e6) {
                        if (price < 0.264147e6) {
                            if (price < 0.213318e6) {
                                if (price < 0.001083e6) {
                                    revert("LUT: Invalid price");
                                } else {
                                    return PriceData(
                                        0.213318e6,
                                        0.188693329162796575e18,
                                        2.410556040105746423e18,
                                        0.001083e6,
                                        0.005263157894736842e18,
                                        10.522774272309483479e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.237671e6) {
                                    return PriceData(
                                        0.264147e6,
                                        0.222936352980619729e18,
                                        2.26657220303422724e18,
                                        0.213318e6,
                                        0.188693329162796575e18,
                                        2.410556040105746423e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.264147e6,
                                        0.222936352980619729e18,
                                        2.26657220303422724e18,
                                        0.237671e6,
                                        0.20510144474217018e18,
                                        2.337718072004858261e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.323531e6) {
                                if (price < 0.292771e6) {
                                    return PriceData(
                                        0.323531e6,
                                        0.263393611744588529e18,
                                        2.128468246736633152e18,
                                        0.264147e6,
                                        0.222936352980619729e18,
                                        2.26657220303422724e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.323531e6,
                                        0.263393611744588529e18,
                                        2.128468246736633152e18,
                                        0.292771e6,
                                        0.242322122805021467e18,
                                        2.196897480682568293e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.356373e6) {
                                    return PriceData(
                                        0.391201e6,
                                        0.311192830511092366e18,
                                        1.994416599735895801e18,
                                        0.323531e6,
                                        0.263393611744588529e18,
                                        2.128468246736633152e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.391201e6,
                                        0.311192830511092366e18,
                                        1.994416599735895801e18,
                                        0.356373e6,
                                        0.286297404070204931e18,
                                        2.061053544007124483e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.546918e6) {
                            if (price < 0.466197e6) {
                                if (price < 0.427871e6) {
                                    return PriceData(
                                        0.466197e6,
                                        0.367666387654882243e18,
                                        1.86249753363281334e18,
                                        0.391201e6,
                                        0.311192830511092366e18,
                                        1.994416599735895801e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.466197e6,
                                        0.367666387654882243e18,
                                        1.86249753363281334e18,
                                        0.427871e6,
                                        0.338253076642491657e18,
                                        1.92831441898410505e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.50596e6) {
                                    return PriceData(
                                        0.546918e6,
                                        0.434388454223632148e18,
                                        1.73068952191306602e18,
                                        0.466197e6,
                                        0.367666387654882243e18,
                                        1.86249753363281334e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.546918e6,
                                        0.434388454223632148e18,
                                        1.73068952191306602e18,
                                        0.50596e6,
                                        0.399637377885741607e18,
                                        1.796709969924970451e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.631434e6) {
                                if (price < 0.588821e6) {
                                    return PriceData(
                                        0.631434e6,
                                        0.513218873137561538e18,
                                        1.596874796852916001e18,
                                        0.546918e6,
                                        0.434388454223632148e18,
                                        1.73068952191306602e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.631434e6,
                                        0.513218873137561538e18,
                                        1.596874796852916001e18,
                                        0.588821e6,
                                        0.472161363286556723e18,
                                        1.664168452923131536e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.67456e6) {
                                    return PriceData(
                                        0.718073e6,
                                        0.606355001344e18,
                                        1.458874768183093584e18,
                                        0.631434e6,
                                        0.513218873137561538e18,
                                        1.596874796852916001e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.718073e6,
                                        0.606355001344e18,
                                        1.458874768183093584e18,
                                        0.67456e6,
                                        0.55784660123648e18,
                                        1.52853450260679824e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    }
                } else {
                    if (price < 0.801931e6) {
                        if (price < 0.780497e6) {
                            if (price < 0.769833e6) {
                                if (price < 0.76195e6) {
                                    return PriceData(
                                        0.769833e6,
                                        0.668971758569680497e18,
                                        1.37471571145172633e18,
                                        0.718073e6,
                                        0.606355001344e18,
                                        1.458874768183093584e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.769833e6,
                                        0.668971758569680497e18,
                                        1.37471571145172633e18,
                                        0.76195e6,
                                        0.659081523200000019e18,
                                        1.387629060213009469e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.775161e6) {
                                    return PriceData(
                                        0.780497e6,
                                        0.682554595010387288e18,
                                        1.357193251389227306e18,
                                        0.769833e6,
                                        0.668971758569680497e18,
                                        1.37471571145172633e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.780497e6,
                                        0.682554595010387288e18,
                                        1.357193251389227306e18,
                                        0.775161e6,
                                        0.675729049060283415e18,
                                        1.365968375000512491e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.791195e6) {
                                if (price < 0.785842e6) {
                                    return PriceData(
                                        0.791195e6,
                                        0.696413218049573679e18,
                                        1.339558007037547016e18,
                                        0.780497e6,
                                        0.682554595010387288e18,
                                        1.357193251389227306e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.791195e6,
                                        0.696413218049573679e18,
                                        1.339558007037547016e18,
                                        0.785842e6,
                                        0.689449085869078049e18,
                                        1.34838993014876074e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.796558e6) {
                                    return PriceData(
                                        0.801931e6,
                                        0.710553227272292309e18,
                                        1.321806771708554873e18,
                                        0.791195e6,
                                        0.696413218049573679e18,
                                        1.339558007037547016e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.801931e6,
                                        0.710553227272292309e18,
                                        1.321806771708554873e18,
                                        0.796558e6,
                                        0.703447694999569495e18,
                                        1.330697084427678423e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.818119e6) {
                            if (price < 0.807315e6) {
                                if (price < 0.806314e6) {
                                    return PriceData(
                                        0.807315e6,
                                        0.717730532598275128e18,
                                        1.312886685708826162e18,
                                        0.801931e6,
                                        0.710553227272292309e18,
                                        1.321806771708554873e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.807315e6,
                                        0.717730532598275128e18,
                                        1.312886685708826162e18,
                                        0.806314e6,
                                        0.716392959999999968e18,
                                        1.314544530202049311e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.812711e6) {
                                    return PriceData(
                                        0.818119e6,
                                        0.732303369654397684e18,
                                        1.294955701044462559e18,
                                        0.807315e6,
                                        0.717730532598275128e18,
                                        1.312886685708826162e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.818119e6,
                                        0.732303369654397684e18,
                                        1.294955701044462559e18,
                                        0.812711e6,
                                        0.724980335957853717e18,
                                        1.303936451137418295e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.828976e6) {
                                if (price < 0.82354e6) {
                                    return PriceData(
                                        0.828976e6,
                                        0.74717209433159637e18,
                                        1.276901231112211654e18,
                                        0.818119e6,
                                        0.732303369654397684e18,
                                        1.294955701044462559e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.828976e6,
                                        0.74717209433159637e18,
                                        1.276901231112211654e18,
                                        0.82354e6,
                                        0.73970037338828043e18,
                                        1.285944077302980215e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.834426e6,
                                    0.754719287203632794e18,
                                    1.267826823523503732e18,
                                    0.828976e6,
                                    0.74717209433159637e18,
                                    1.276901231112211654e18,
                                    1e18
                                );
                            }
                        }
                    }
                }
            } else {
                if (price < 0.907266e6) {
                    if (price < 0.873109e6) {
                        if (price < 0.851493e6) {
                            if (price < 0.845379e6) {
                                if (price < 0.839894e6) {
                                    return PriceData(
                                        0.845379e6,
                                        0.770043145805155316e18,
                                        1.249582020939133509e18,
                                        0.834426e6,
                                        0.754719287203632794e18,
                                        1.267826823523503732e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.845379e6,
                                        0.770043145805155316e18,
                                        1.249582020939133509e18,
                                        0.839894e6,
                                        0.762342714347103767e18,
                                        1.258720525989716954e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.850882e6) {
                                    return PriceData(
                                        0.851493e6,
                                        0.778688000000000047e18,
                                        1.239392846883276889e18,
                                        0.845379e6,
                                        0.770043145805155316e18,
                                        1.249582020939133509e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.851493e6,
                                        0.778688000000000047e18,
                                        1.239392846883276889e18,
                                        0.850882e6,
                                        0.777821359399146761e18,
                                        1.240411002374896432e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.86195e6) {
                                if (price < 0.856405e6) {
                                    return PriceData(
                                        0.86195e6,
                                        0.793614283643655494e18,
                                        1.221970262376178118e18,
                                        0.851493e6,
                                        0.778688000000000047e18,
                                        1.239392846883276889e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.86195e6,
                                        0.793614283643655494e18,
                                        1.221970262376178118e18,
                                        0.856405e6,
                                        0.785678140807218983e18,
                                        1.231207176501035727e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.867517e6) {
                                    return PriceData(
                                        0.873109e6,
                                        0.809727868221258529e18,
                                        1.203396114006087814e18,
                                        0.86195e6,
                                        0.793614283643655494e18,
                                        1.221970262376178118e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.873109e6,
                                        0.809727868221258529e18,
                                        1.203396114006087814e18,
                                        0.867517e6,
                                        0.801630589539045979e18,
                                        1.212699992596070864e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.895753e6) {
                            if (price < 0.884372e6) {
                                if (price < 0.878727e6) {
                                    return PriceData(
                                        0.884372e6,
                                        0.826168623835586646e18,
                                        1.18468659352065786e18,
                                        0.873109e6,
                                        0.809727868221258529e18,
                                        1.203396114006087814e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.884372e6,
                                        0.826168623835586646e18,
                                        1.18468659352065786e18,
                                        0.878727e6,
                                        0.817906937597230987e18,
                                        1.194058388444914964e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.890047e6) {
                                    return PriceData(
                                        0.895753e6,
                                        0.84294319338392687e18,
                                        1.16583998975613734e18,
                                        0.884372e6,
                                        0.826168623835586646e18,
                                        1.18468659352065786e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.895753e6,
                                        0.84294319338392687e18,
                                        1.16583998975613734e18,
                                        0.890047e6,
                                        0.834513761450087599e18,
                                        1.17528052342063094e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.901491e6) {
                                if (price < 0.898085e6) {
                                    return PriceData(
                                        0.901491e6,
                                        0.851457771094875637e18,
                                        1.156364822443562979e18,
                                        0.895753e6,
                                        0.84294319338392687e18,
                                        1.16583998975613734e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.901491e6,
                                        0.851457771094875637e18,
                                        1.156364822443562979e18,
                                        0.898085e6,
                                        0.846400000000000041e18,
                                        1.161985895520041945e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.907266e6,
                                    0.860058354641288547e18,
                                    1.146854870623147615e18,
                                    0.901491e6,
                                    0.851457771094875637e18,
                                    1.156364822443562979e18,
                                    1e18
                                );
                            }
                        }
                    }
                } else {
                    if (price < 0.948888e6) {
                        if (price < 0.930767e6) {
                            if (price < 0.918932e6) {
                                if (price < 0.913079e6) {
                                    return PriceData(
                                        0.918932e6,
                                        0.877521022998967948e18,
                                        1.127730111926438461e18,
                                        0.907266e6,
                                        0.860058354641288547e18,
                                        1.146854870623147615e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.918932e6,
                                        0.877521022998967948e18,
                                        1.127730111926438461e18,
                                        0.913079e6,
                                        0.868745812768978332e18,
                                        1.137310003616810228e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.924827e6) {
                                    return PriceData(
                                        0.930767e6,
                                        0.895338254258716493e18,
                                        1.10846492868530544e18,
                                        0.918932e6,
                                        0.877521022998967948e18,
                                        1.127730111926438461e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.930767e6,
                                        0.895338254258716493e18,
                                        1.10846492868530544e18,
                                        0.924827e6,
                                        0.88638487171612923e18,
                                        1.118115108274055913e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.942795e6) {
                                if (price < 0.936756e6) {
                                    return PriceData(
                                        0.942795e6,
                                        0.913517247483640937e18,
                                        1.089058909134983155e18,
                                        0.930767e6,
                                        0.895338254258716493e18,
                                        1.10846492868530544e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.942795e6,
                                        0.913517247483640937e18,
                                        1.089058909134983155e18,
                                        0.936756e6,
                                        0.90438207500880452e18,
                                        1.09877953361768621e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.947076e6) {
                                    return PriceData(
                                        0.948888e6,
                                        0.922744694427920065e18,
                                        1.079303068129318754e18,
                                        0.942795e6,
                                        0.913517247483640937e18,
                                        1.089058909134983155e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.948888e6,
                                        0.922744694427920065e18,
                                        1.079303068129318754e18,
                                        0.947076e6,
                                        0.92000000000000004e18,
                                        1.082198372170484424e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 0.973868e6) {
                            if (price < 0.961249e6) {
                                if (price < 0.955039e6) {
                                    return PriceData(
                                        0.961249e6,
                                        0.941480149400999999e18,
                                        1.059685929936267312e18,
                                        0.948888e6,
                                        0.922744694427920065e18,
                                        1.079303068129318754e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.961249e6,
                                        0.941480149400999999e18,
                                        1.059685929936267312e18,
                                        0.955039e6,
                                        0.932065347906990027e18,
                                        1.069512051592246715e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 0.967525e6) {
                                    return PriceData(
                                        0.973868e6,
                                        0.960596010000000056e18,
                                        1.039928808315135234e18,
                                        0.961249e6,
                                        0.941480149400999999e18,
                                        1.059685929936267312e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.973868e6,
                                        0.960596010000000056e18,
                                        1.039928808315135234e18,
                                        0.967525e6,
                                        0.950990049900000023e18,
                                        1.049824804368118425e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 0.986773e6) {
                                if (price < 0.980283e6) {
                                    return PriceData(
                                        0.986773e6,
                                        0.980099999999999971e18,
                                        1.020032908506394831e18,
                                        0.973868e6,
                                        0.960596010000000056e18,
                                        1.039928808315135234e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.986773e6,
                                        0.980099999999999971e18,
                                        1.020032908506394831e18,
                                        0.980283e6,
                                        0.970299000000000134e18,
                                        1.029998108905910481e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.993344e6,
                                    0.989999999999999991e18,
                                    1.01003344631248293e18,
                                    0.986773e6,
                                    0.980099999999999971e18,
                                    1.020032908506394831e18,
                                    1e18
                                );
                            }
                        }
                    }
                }
            }
        } else {
            if (price < 1.211166e6) {
                if (price < 1.09577e6) {
                    if (price < 1.048893e6) {
                        if (price < 1.027293e6) {
                            if (price < 1.01345e6) {
                                if (price < 1.006679e6) {
                                    return PriceData(
                                        1.01345e6,
                                        1.020100000000000007e18,
                                        0.980033797419900599e18,
                                        0.993344e6,
                                        0.989999999999999991e18,
                                        1.01003344631248293e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.01345e6,
                                        1.020100000000000007e18,
                                        0.980033797419900599e18,
                                        1.006679e6,
                                        1.010000000000000009e18,
                                        0.990033224058159078e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.020319e6) {
                                    return PriceData(
                                        1.027293e6,
                                        1.040604010000000024e18,
                                        0.959938599971011053e18,
                                        1.01345e6,
                                        1.020100000000000007e18,
                                        0.980033797419900599e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.027293e6,
                                        1.040604010000000024e18,
                                        0.959938599971011053e18,
                                        1.020319e6,
                                        1.030300999999999911e18,
                                        0.970002111104709575e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.034375e6) {
                                if (price < 1.033686e6) {
                                    return PriceData(
                                        1.034375e6,
                                        1.051010050100000148e18,
                                        0.949843744564435544e18,
                                        1.027293e6,
                                        1.040604010000000024e18,
                                        0.959938599971011053e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.034375e6,
                                        1.051010050100000148e18,
                                        0.949843744564435544e18,
                                        1.033686e6,
                                        1.050000000000000044e18,
                                        0.950820553711780869e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.041574e6) {
                                    return PriceData(
                                        1.048893e6,
                                        1.072135352107010053e18,
                                        0.929562163027227939e18,
                                        1.034375e6,
                                        1.051010050100000148e18,
                                        0.949843744564435544e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.048893e6,
                                        1.072135352107010053e18,
                                        0.929562163027227939e18,
                                        1.041574e6,
                                        1.061520150601000134e18,
                                        0.93971807302139454e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 1.071652e6) {
                            if (price < 1.063925e6) {
                                if (price < 1.056342e6) {
                                    return PriceData(
                                        1.063925e6,
                                        1.093685272684360887e18,
                                        0.90916219829307332e18,
                                        1.048893e6,
                                        1.072135352107010053e18,
                                        0.929562163027227939e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.063925e6,
                                        1.093685272684360887e18,
                                        0.90916219829307332e18,
                                        1.056342e6,
                                        1.082856705628080007e18,
                                        0.919376643827810258e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.070147e6) {
                                    return PriceData(
                                        1.071652e6,
                                        1.104622125411204525e18,
                                        0.89891956503043724e18,
                                        1.063925e6,
                                        1.093685272684360887e18,
                                        0.90916219829307332e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.071652e6,
                                        1.104622125411204525e18,
                                        0.89891956503043724e18,
                                        1.070147e6,
                                        1.102500000000000036e18,
                                        0.900901195775543062e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.087566e6) {
                                if (price < 1.079529e6) {
                                    return PriceData(
                                        1.087566e6,
                                        1.126825030131969774e18,
                                        0.878352981447521719e18,
                                        1.071652e6,
                                        1.104622125411204525e18,
                                        0.89891956503043724e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.087566e6,
                                        1.126825030131969774e18,
                                        0.878352981447521719e18,
                                        1.079529e6,
                                        1.115668346665316557e18,
                                        0.888649540545595529e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.09577e6,
                                    1.1380932804332895e18,
                                    0.868030806693890433e18,
                                    1.087566e6,
                                    1.126825030131969774e18,
                                    0.878352981447521719e18,
                                    1e18
                                );
                            }
                        }
                    }
                } else {
                    if (price < 1.15496e6) {
                        if (price < 1.121482e6) {
                            if (price < 1.110215e6) {
                                if (price < 1.104151e6) {
                                    return PriceData(
                                        1.110215e6,
                                        1.157625000000000126e18,
                                        0.850322213751246947e18,
                                        1.09577e6,
                                        1.1380932804332895e18,
                                        0.868030806693890433e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.110215e6,
                                        1.157625000000000126e18,
                                        0.850322213751246947e18,
                                        1.104151e6,
                                        1.149474213237622333e18,
                                        0.857683999872391523e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.112718e6) {
                                    return PriceData(
                                        1.121482e6,
                                        1.172578644923698565e18,
                                        0.836920761422192294e18,
                                        1.110215e6,
                                        1.157625000000000126e18,
                                        0.850322213751246947e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.121482e6,
                                        1.172578644923698565e18,
                                        0.836920761422192294e18,
                                        1.112718e6,
                                        1.160968955369998667e18,
                                        0.847313611512600207e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.139642e6) {
                                if (price < 1.130452e6) {
                                    return PriceData(
                                        1.139642e6,
                                        1.196147475686665018e18,
                                        0.8160725157999702e18,
                                        1.121482e6,
                                        1.172578644923698565e18,
                                        0.836920761422192294e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.139642e6,
                                        1.196147475686665018e18,
                                        0.8160725157999702e18,
                                        1.130452e6,
                                        1.184304431372935618e18,
                                        0.826506641040327228e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.149062e6) {
                                    return PriceData(
                                        1.15496e6,
                                        1.21550625000000001e18,
                                        0.799198479643147719e18,
                                        1.139642e6,
                                        1.196147475686665018e18,
                                        0.8160725157999702e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.15496e6,
                                        1.21550625000000001e18,
                                        0.799198479643147719e18,
                                        1.149062e6,
                                        1.208108950443531393e18,
                                        0.805619727489791271e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 1.189304e6) {
                            if (price < 1.168643e6) {
                                if (price < 1.158725e6) {
                                    return PriceData(
                                        1.168643e6,
                                        1.232391940347446369e18,
                                        0.784663924675502389e18,
                                        1.15496e6,
                                        1.21550625000000001e18,
                                        0.799198479643147719e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.168643e6,
                                        1.232391940347446369e18,
                                        0.784663924675502389e18,
                                        1.158725e6,
                                        1.22019003994796682e18,
                                        0.795149696605042422e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.178832e6) {
                                    return PriceData(
                                        1.189304e6,
                                        1.257163018348430139e18,
                                        0.763651582672810969e18,
                                        1.168643e6,
                                        1.232391940347446369e18,
                                        0.784663924675502389e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.189304e6,
                                        1.257163018348430139e18,
                                        0.763651582672810969e18,
                                        1.178832e6,
                                        1.244715859750920917e18,
                                        0.774163996557160172e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.205768e6) {
                                if (price < 1.200076e6) {
                                    return PriceData(
                                        1.205768e6,
                                        1.276281562499999911e18,
                                        0.747685899578659385e18,
                                        1.189304e6,
                                        1.257163018348430139e18,
                                        0.763651582672810969e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.205768e6,
                                        1.276281562499999911e18,
                                        0.747685899578659385e18,
                                        1.200076e6,
                                        1.269734648531914534e18,
                                        0.753128441185147435e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.211166e6,
                                    1.282431995017233595e18,
                                    0.74259642008426785e18,
                                    1.205768e6,
                                    1.276281562499999911e18,
                                    0.747685899578659385e18,
                                    1e18
                                );
                            }
                        }
                    }
                }
            } else {
                if (price < 1.393403e6) {
                    if (price < 1.299217e6) {
                        if (price < 1.259043e6) {
                            if (price < 1.234362e6) {
                                if (price < 1.222589e6) {
                                    return PriceData(
                                        1.234362e6,
                                        1.308208878117080198e18,
                                        0.721513591905860174e18,
                                        1.211166e6,
                                        1.282431995017233595e18,
                                        0.74259642008426785e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.234362e6,
                                        1.308208878117080198e18,
                                        0.721513591905860174e18,
                                        1.222589e6,
                                        1.295256314967406119e18,
                                        0.732057459169776381e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.246507e6) {
                                    return PriceData(
                                        1.259043e6,
                                        1.33450387656723346e18,
                                        0.700419750561125598e18,
                                        1.234362e6,
                                        1.308208878117080198e18,
                                        0.721513591905860174e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.259043e6,
                                        1.33450387656723346e18,
                                        0.700419750561125598e18,
                                        1.246507e6,
                                        1.321290966898250874e18,
                                        0.710966947125877935e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.271991e6) {
                                if (price < 1.264433e6) {
                                    return PriceData(
                                        1.271991e6,
                                        1.347848915332905628e18,
                                        0.689874326166576179e18,
                                        1.259043e6,
                                        1.33450387656723346e18,
                                        0.700419750561125598e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.271991e6,
                                        1.347848915332905628e18,
                                        0.689874326166576179e18,
                                        1.264433e6,
                                        1.340095640624999973e18,
                                        0.695987932996588454e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.285375e6) {
                                    return PriceData(
                                        1.299217e6,
                                        1.374940678531097138e18,
                                        0.668798587125333244e18,
                                        1.271991e6,
                                        1.347848915332905628e18,
                                        0.689874326166576179e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.299217e6,
                                        1.374940678531097138e18,
                                        0.668798587125333244e18,
                                        1.285375e6,
                                        1.361327404486234682e18,
                                        0.67933309721453039e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 1.343751e6) {
                            if (price < 1.328377e6) {
                                if (price < 1.313542e6) {
                                    return PriceData(
                                        1.328377e6,
                                        1.402576986169572049e18,
                                        0.647760320838866033e18,
                                        1.299217e6,
                                        1.374940678531097138e18,
                                        0.668798587125333244e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.328377e6,
                                        1.402576986169572049e18,
                                        0.647760320838866033e18,
                                        1.313542e6,
                                        1.38869008531640814e18,
                                        0.658273420002602916e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.333292e6) {
                                    return PriceData(
                                        1.343751e6,
                                        1.416602756031267951e18,
                                        0.637262115356114656e18,
                                        1.328377e6,
                                        1.402576986169572049e18,
                                        0.647760320838866033e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.343751e6,
                                        1.416602756031267951e18,
                                        0.637262115356114656e18,
                                        1.333292e6,
                                        1.407100422656250016e18,
                                        0.644361360672887962e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.376232e6) {
                                if (price < 1.359692e6) {
                                    return PriceData(
                                        1.376232e6,
                                        1.445076471427496179e18,
                                        0.616322188162944262e18,
                                        1.343751e6,
                                        1.416602756031267951e18,
                                        0.637262115356114656e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.376232e6,
                                        1.445076471427496179e18,
                                        0.616322188162944262e18,
                                        1.359692e6,
                                        1.430768783591580551e18,
                                        0.626781729444674585e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.393403e6,
                                    1.459527236141771489e18,
                                    0.605886614260108591e18,
                                    1.376232e6,
                                    1.445076471427496179e18,
                                    0.616322188162944262e18,
                                    1e18
                                );
                            }
                        }
                    }
                } else {
                    if (price < 2.209802e6) {
                        if (price < 1.514667e6) {
                            if (price < 1.415386e6) {
                                if (price < 1.41124e6) {
                                    return PriceData(
                                        1.415386e6,
                                        1.47745544378906235e18,
                                        0.593119977480511928e18,
                                        1.393403e6,
                                        1.459527236141771489e18,
                                        0.605886614260108591e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.415386e6,
                                        1.47745544378906235e18,
                                        0.593119977480511928e18,
                                        1.41124e6,
                                        1.474122508503188822e18,
                                        0.595478226183906334e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.42978e6) {
                                    return PriceData(
                                        1.514667e6,
                                        1.551328215978515557e18,
                                        0.54263432113736132e18,
                                        1.415386e6,
                                        1.47745544378906235e18,
                                        0.593119977480511928e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.514667e6,
                                        1.551328215978515557e18,
                                        0.54263432113736132e18,
                                        1.42978e6,
                                        1.488863733588220883e18,
                                        0.585100335536025584e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 1.786708e6) {
                                if (price < 1.636249e6) {
                                    return PriceData(
                                        1.786708e6,
                                        1.710339358116313546e18,
                                        0.445648172809785581e18,
                                        1.514667e6,
                                        1.551328215978515557e18,
                                        0.54263432113736132e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.786708e6,
                                        1.710339358116313546e18,
                                        0.445648172809785581e18,
                                        1.636249e6,
                                        1.628894626777441568e18,
                                        0.493325115988533236e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 1.974398e6) {
                                    return PriceData(
                                        2.209802e6,
                                        1.885649142323235772e18,
                                        0.357031765135700119e18,
                                        1.786708e6,
                                        1.710339358116313546e18,
                                        0.445648172809785581e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        2.209802e6,
                                        1.885649142323235772e18,
                                        0.357031765135700119e18,
                                        1.974398e6,
                                        1.79585632602212919e18,
                                        0.400069510798421513e18,
                                        1e18
                                    );
                                }
                            }
                        }
                    } else {
                        if (price < 3.931396e6) {
                            if (price < 2.878327e6) {
                                if (price < 2.505865e6) {
                                    return PriceData(
                                        2.878327e6,
                                        2.078928179411367427e18,
                                        0.28000760254479623e18,
                                        2.209802e6,
                                        1.885649142323235772e18,
                                        0.357031765135700119e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        2.878327e6,
                                        2.078928179411367427e18,
                                        0.28000760254479623e18,
                                        2.505865e6,
                                        1.97993159943939756e18,
                                        0.316916199929126341e18,
                                        1e18
                                    );
                                }
                            } else {
                                if (price < 3.346057e6) {
                                    return PriceData(
                                        3.931396e6,
                                        2.292018317801032268e18,
                                        0.216340086006769544e18,
                                        2.878327e6,
                                        2.078928179411367427e18,
                                        0.28000760254479623e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        3.931396e6,
                                        2.292018317801032268e18,
                                        0.216340086006769544e18,
                                        3.346057e6,
                                        2.182874588381935599e18,
                                        0.246470170347584949e18,
                                        1e18
                                    );
                                }
                            }
                        } else {
                            if (price < 10.709509e6) {
                                if (price < 4.660591e6) {
                                    return PriceData(
                                        10.709509e6,
                                        3.0e18,
                                        0.103912563829966526e18,
                                        3.931396e6,
                                        2.292018317801032268e18,
                                        0.216340086006769544e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        10.709509e6,
                                        3.0e18,
                                        0.103912563829966526e18,
                                        4.660591e6,
                                        2.406619233691083881e18,
                                        0.189535571483960663e18,
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
