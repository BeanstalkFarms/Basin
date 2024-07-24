// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ILookupTable} from "src/interfaces/ILookupTable.sol";

/**
 * @title Stable2LUT1
 * @author Deadmanwalking, brean
 * @notice Implements a lookup table of estimations used in the Stableswap Well Function
 * to calculate the token ratios in a Stableswap pool for a given price.
 */
contract Stable2LUT1 is ILookupTable {
    /**
     * @notice Returns the amplification coefficient (A parameter) used to calculate the estimates.
     * @return The amplification coefficient.
     * @dev 2 decimal precision.
     */
    function getAParameter() external pure returns (uint256) {
        return 100;
    }

    /**
     * @notice Returns the estimated range of reserve ratios for a given price,
     * assuming one token reserve remains constant.
     */
    function getRatiosFromPriceLiquidity(uint256 price) external pure returns (PriceData memory) {
        if (price < 1.006758e6) {
            if (price < 0.885627e6) {
                if (price < 0.59332e6) {
                    if (price < 0.404944e6) {
                        if (price < 0.30624e6) {
                            if (price < 0.27702e6) {
                                if (price < 0.001083e6) {
                                    revert("LUT: Invalid price");
                                } else {
                                    return
                                        PriceData(0.27702e6, 0, 9.646293093274934449e18, 0.001083e6, 0, 2000e18, 1e18);
                                }
                            } else {
                                return PriceData(
                                    0.30624e6, 0, 8.612761690424049377e18, 0.27702e6, 0, 9.646293093274934449e18, 1e18
                                );
                            }
                        } else {
                            if (price < 0.370355e6) {
                                if (price < 0.337394e6) {
                                    return PriceData(
                                        0.337394e6,
                                        0,
                                        7.689965795021471706e18,
                                        0.30624e6,
                                        0,
                                        8.612761690424049377e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.370355e6,
                                        0,
                                        6.866040888412029197e18,
                                        0.337394e6,
                                        0,
                                        7.689965795021471706e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.404944e6, 0, 6.130393650367882863e18, 0.370355e6, 0, 6.866040888412029197e18, 1e18
                                );
                            }
                        }
                    } else {
                        if (price < 0.516039e6) {
                            if (price < 0.478063e6) {
                                if (price < 0.440934e6) {
                                    return PriceData(
                                        0.440934e6,
                                        0,
                                        5.473565759257038366e18,
                                        0.404944e6,
                                        0,
                                        6.130393650367882863e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.478063e6,
                                        0,
                                        4.887112285050926097e18,
                                        0.440934e6,
                                        0,
                                        5.473565759257038366e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.516039e6, 0, 4.363493111652613443e18, 0.478063e6, 0, 4.887112285050926097e18, 1e18
                                );
                            }
                        } else {
                            if (price < 0.554558e6) {
                                return PriceData(
                                    0.554558e6, 0, 3.89597599254697613e18, 0.516039e6, 0, 4.363493111652613443e18, 1e18
                                );
                            } else {
                                return PriceData(
                                    0.59332e6, 0, 3.478549993345514402e18, 0.554558e6, 0, 3.89597599254697613e18, 1e18
                                );
                            }
                        }
                    }
                } else {
                    if (price < 0.782874e6) {
                        if (price < 0.708539e6) {
                            if (price < 0.670518e6) {
                                if (price < 0.632052e6) {
                                    return PriceData(
                                        0.632052e6,
                                        0,
                                        3.105848208344209382e18,
                                        0.59332e6,
                                        0,
                                        3.478549993345514402e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.670518e6,
                                        0,
                                        2.773078757450186949e18,
                                        0.632052e6,
                                        0,
                                        3.105848208344209382e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.708539e6, 0, 2.475963176294809553e18, 0.670518e6, 0, 2.773078757450186949e18, 1e18
                                );
                            }
                        } else {
                            if (price < 0.746003e6) {
                                return PriceData(
                                    0.746003e6, 0, 2.210681407406080101e18, 0.708539e6, 0, 2.475963176294809553e18, 1e18
                                );
                            } else {
                                return PriceData(
                                    0.782874e6, 0, 1.973822685183999948e18, 0.746003e6, 0, 2.210681407406080101e18, 1e18
                                );
                            }
                        }
                    } else {
                        if (price < 0.873157e6) {
                            if (price < 0.855108e6) {
                                if (price < 0.819199e6) {
                                    return PriceData(
                                        0.819199e6,
                                        0,
                                        1.762341683200000064e18,
                                        0.782874e6,
                                        0,
                                        1.973822685183999948e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.855108e6,
                                        0,
                                        1.573519359999999923e18,
                                        0.819199e6,
                                        0,
                                        1.762341683200000064e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.873157e6, 0, 1.485947395978354457e18, 0.855108e6, 0, 1.573519359999999923e18, 1e18
                                );
                            }
                        } else {
                            if (price < 0.879393e6) {
                                return PriceData(
                                    0.879393e6, 0, 1.456811172527798348e18, 0.873157e6, 0, 1.485947395978354457e18, 1e18
                                );
                            } else {
                                return PriceData(
                                    0.885627e6, 0, 1.428246247576273165e18, 0.879393e6, 0, 1.456811172527798348e18, 1e18
                                );
                            }
                        }
                    }
                }
            } else {
                if (price < 0.94201e6) {
                    if (price < 0.916852e6) {
                        if (price < 0.898101e6) {
                            if (price < 0.891863e6) {
                                if (price < 0.89081e6) {
                                    return PriceData(
                                        0.89081e6,
                                        0,
                                        1.404927999999999955e18,
                                        0.885627e6,
                                        0,
                                        1.428246247576273165e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.891863e6,
                                        0,
                                        1.400241419192424397e18,
                                        0.89081e6,
                                        0,
                                        1.404927999999999955e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.898101e6, 0, 1.372785705090612263e18, 0.891863e6, 0, 1.400241419192424397e18, 1e18
                                );
                            }
                        } else {
                            if (price < 0.910594e6) {
                                if (price < 0.904344e6) {
                                    return PriceData(
                                        0.904344e6,
                                        0,
                                        1.345868338324129665e18,
                                        0.898101e6,
                                        0,
                                        1.372785705090612263e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.910594e6,
                                        0,
                                        1.319478763062872151e18,
                                        0.904344e6,
                                        0,
                                        1.345868338324129665e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.916852e6, 0, 1.293606630453796313e18, 0.910594e6, 0, 1.319478763062872151e18, 1e18
                                );
                            }
                        }
                    } else {
                        if (price < 0.929402e6) {
                            if (price < 0.9266e6) {
                                if (price < 0.92312e6) {
                                    return PriceData(
                                        0.92312e6,
                                        0,
                                        1.268241794562545266e18,
                                        0.916852e6,
                                        0,
                                        1.293606630453796313e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.9266e6,
                                        0,
                                        1.254399999999999959e18,
                                        0.92312e6,
                                        0,
                                        1.268241794562545266e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.929402e6, 0, 1.243374308394652239e18, 0.9266e6, 0, 1.254399999999999959e18, 1e18
                                );
                            }
                        } else {
                            if (price < 0.935697e6) {
                                return PriceData(
                                    0.935697e6, 0, 1.218994419994757328e18, 0.929402e6, 0, 1.243374308394652239e18, 1e18
                                );
                            } else {
                                return PriceData(
                                    0.94201e6, 0, 1.195092568622310836e18, 0.935697e6, 0, 1.218994419994757328e18, 1e18
                                );
                            }
                        }
                    }
                } else {
                    if (price < 0.96748e6) {
                        if (price < 0.961075e6) {
                            if (price < 0.954697e6) {
                                if (price < 0.948343e6) {
                                    return PriceData(
                                        0.948343e6,
                                        0,
                                        1.171659381002265521e18,
                                        0.94201e6,
                                        0,
                                        1.195092568622310836e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.954697e6,
                                        0,
                                        1.14868566764928004e18,
                                        0.948343e6,
                                        0,
                                        1.171659381002265521e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.961075e6, 0, 1.12616241926400007e18, 0.954697e6, 0, 1.14868566764928004e18, 1e18
                                );
                            }
                        } else {
                            if (price < 0.962847e6) {
                                return PriceData(
                                    0.962847e6, 0, 1.120000000000000107e18, 0.961075e6, 0, 1.12616241926400007e18, 1e18
                                );
                            } else {
                                return PriceData(
                                    0.96748e6, 0, 1.104080803200000016e18, 0.962847e6, 0, 1.120000000000000107e18, 1e18
                                );
                            }
                        }
                    } else {
                        if (price < 0.986882e6) {
                            if (price < 0.98038e6) {
                                if (price < 0.973914e6) {
                                    return PriceData(
                                        0.973914e6,
                                        0,
                                        1.082432159999999977e18,
                                        0.96748e6,
                                        0,
                                        1.104080803200000016e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        0.98038e6,
                                        0,
                                        1.061208000000000151e18,
                                        0.973914e6,
                                        0,
                                        1.082432159999999977e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    0.986882e6, 0, 1.040399999999999991e18, 0.98038e6, 0, 1.061208000000000151e18, 1e18
                                );
                            }
                        } else {
                            if (price < 0.993421e6) {
                                return PriceData(
                                    0.993421e6, 0, 1.020000000000000018e18, 0.986882e6, 0, 1.040399999999999991e18, 1e18
                                );
                            } else {
                                return PriceData(
                                    1.006758e6, 0, 0.980000000000000093e18, 0.993421e6, 0, 1.020000000000000018e18, 1e18
                                );
                            }
                        }
                    }
                }
            }
        } else {
            if (price < 1.140253e6) {
                if (price < 1.077582e6) {
                    if (price < 1.04366e6) {
                        if (price < 1.027335e6) {
                            if (price < 1.020422e6) {
                                if (price < 1.013564e6) {
                                    return PriceData(
                                        1.013564e6,
                                        0,
                                        0.960400000000000031e18,
                                        1.006758e6,
                                        0,
                                        0.980000000000000093e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.020422e6,
                                        0,
                                        0.941192000000000029e18,
                                        1.013564e6,
                                        0,
                                        0.960400000000000031e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.027335e6, 0, 0.922368159999999992e18, 1.020422e6, 0, 0.941192000000000029e18, 1e18
                                );
                            }
                        } else {
                            if (price < 1.041342e6) {
                                if (price < 1.034307e6) {
                                    return PriceData(
                                        1.034307e6,
                                        0,
                                        0.903920796799999926e18,
                                        1.027335e6,
                                        0,
                                        0.922368159999999992e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.041342e6,
                                        0,
                                        0.885842380864000023e18,
                                        1.034307e6,
                                        0,
                                        0.903920796799999926e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.04366e6, 0, 0.880000000000000004e18, 1.041342e6, 0, 0.885842380864000023e18, 1e18
                                );
                            }
                        }
                    } else {
                        if (price < 1.062857e6) {
                            if (price < 1.055613e6) {
                                if (price < 1.048443e6) {
                                    return PriceData(
                                        1.048443e6,
                                        0,
                                        0.868125533246720038e18,
                                        1.04366e6,
                                        0,
                                        0.880000000000000004e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.055613e6,
                                        0,
                                        0.8507630225817856e18,
                                        1.048443e6,
                                        0,
                                        0.868125533246720038e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.062857e6, 0, 0.833747762130149894e18, 1.055613e6, 0, 0.8507630225817856e18, 1e18
                                );
                            }
                        } else {
                            if (price < 1.070179e6) {
                                return PriceData(
                                    1.070179e6, 0, 0.81707280688754691e18, 1.062857e6, 0, 0.833747762130149894e18, 1e18
                                );
                            } else {
                                return PriceData(
                                    1.077582e6, 0, 0.800731350749795956e18, 1.070179e6, 0, 0.81707280688754691e18, 1e18
                                );
                            }
                        }
                    }
                } else {
                    if (price < 1.108094e6) {
                        if (price < 1.09265e6) {
                            if (price < 1.090025e6) {
                                if (price < 1.085071e6) {
                                    return PriceData(
                                        1.085071e6,
                                        0,
                                        0.784716723734800059e18,
                                        1.077582e6,
                                        0,
                                        0.800731350749795956e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.090025e6,
                                        0,
                                        0.774399999999999977e18,
                                        1.085071e6,
                                        0,
                                        0.784716723734800059e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.09265e6, 0, 0.769022389260104022e18, 1.090025e6, 0, 0.774399999999999977e18, 1e18
                                );
                            }
                        } else {
                            if (price < 1.100323e6) {
                                return PriceData(
                                    1.100323e6, 0, 0.753641941474902044e18, 1.09265e6, 0, 0.769022389260104022e18, 1e18
                                );
                            } else {
                                return PriceData(
                                    1.108094e6, 0, 0.738569102645403985e18, 1.100323e6, 0, 0.753641941474902044e18, 1e18
                                );
                            }
                        }
                    } else {
                        if (price < 1.132044e6) {
                            if (price < 1.123949e6) {
                                if (price < 1.115967e6) {
                                    return PriceData(
                                        1.115967e6,
                                        0,
                                        0.723797720592495919e18,
                                        1.108094e6,
                                        0,
                                        0.738569102645403985e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.123949e6,
                                        0,
                                        0.709321766180645907e18,
                                        1.115967e6,
                                        0,
                                        0.723797720592495919e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.132044e6, 0, 0.695135330857033051e18, 1.123949e6, 0, 0.709321766180645907e18, 1e18
                                );
                            }
                        } else {
                            if (price < 1.14011e6) {
                                return PriceData(
                                    1.14011e6, 0, 0.681471999999999967e18, 1.132044e6, 0, 0.695135330857033051e18, 1e18
                                );
                            } else {
                                return PriceData(
                                    1.140253e6, 0, 0.681232624239892393e18, 1.14011e6, 0, 0.681471999999999967e18, 1e18
                                );
                            }
                        }
                    }
                }
            } else {
                if (price < 2.01775e6) {
                    if (price < 1.403579e6) {
                        if (price < 1.256266e6) {
                            if (price < 1.195079e6) {
                                if (price < 1.148586e6) {
                                    return PriceData(
                                        1.148586e6,
                                        0,
                                        0.667607971755094454e18,
                                        1.140253e6,
                                        0,
                                        0.681232624239892393e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.195079e6,
                                        0,
                                        0.599695360000000011e18,
                                        1.148586e6,
                                        0,
                                        0.667607971755094454e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.256266e6, 0, 0.527731916799999978e18, 1.195079e6, 0, 0.599695360000000011e18, 1e18
                                );
                            }
                        } else {
                            if (price < 1.325188e6) {
                                return PriceData(
                                    1.325188e6, 0, 0.464404086784000025e18, 1.256266e6, 0, 0.527731916799999978e18, 1e18
                                );
                            } else {
                                return PriceData(
                                    1.403579e6, 0, 0.408675596369920013e18, 1.325188e6, 0, 0.464404086784000025e18, 1e18
                                );
                            }
                        }
                    } else {
                        if (price < 1.716848e6) {
                            if (price < 1.596984e6) {
                                if (price < 1.493424e6) {
                                    return PriceData(
                                        1.493424e6,
                                        0,
                                        0.359634524805529598e18,
                                        1.403579e6,
                                        0,
                                        0.408675596369920013e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        1.596984e6,
                                        0,
                                        0.316478381828866062e18,
                                        1.493424e6,
                                        0,
                                        0.359634524805529598e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    1.716848e6, 0, 0.278500976009402101e18, 1.596984e6, 0, 0.316478381828866062e18, 1e18
                                );
                            }
                        } else {
                            if (price < 1.855977e6) {
                                return PriceData(
                                    1.855977e6, 0, 0.245080858888273884e18, 1.716848e6, 0, 0.278500976009402101e18, 1e18
                                );
                            } else {
                                return PriceData(
                                    2.01775e6, 0, 0.215671155821681004e18, 1.855977e6, 0, 0.245080858888273884e18, 1e18
                                );
                            }
                        }
                    }
                } else {
                    if (price < 3.322705e6) {
                        if (price < 2.680458e6) {
                            if (price < 2.425256e6) {
                                if (price < 2.206036e6) {
                                    return PriceData(
                                        2.206036e6,
                                        0,
                                        0.189790617123079292e18,
                                        2.01775e6,
                                        0,
                                        0.215671155821681004e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        2.425256e6,
                                        0,
                                        0.167015743068309769e18,
                                        2.206036e6,
                                        0,
                                        0.189790617123079292e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    2.680458e6, 0, 0.146973853900112583e18, 2.425256e6, 0, 0.167015743068309769e18, 1e18
                                );
                            }
                        } else {
                            if (price < 2.977411e6) {
                                return PriceData(
                                    2.977411e6, 0, 0.129336991432099091e18, 2.680458e6, 0, 0.146973853900112583e18, 1e18
                                );
                            } else {
                                return PriceData(
                                    3.322705e6, 0, 0.113816552460247203e18, 2.977411e6, 0, 0.129336991432099091e18, 1e18
                                );
                            }
                        }
                    } else {
                        if (price < 4.729321e6) {
                            if (price < 4.189464e6) {
                                if (price < 3.723858e6) {
                                    return PriceData(
                                        3.723858e6,
                                        0,
                                        0.100158566165017532e18,
                                        3.322705e6,
                                        0,
                                        0.113816552460247203e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        4.189464e6,
                                        0,
                                        0.088139538225215433e18,
                                        3.723858e6,
                                        0,
                                        0.100158566165017532e18,
                                        1e18
                                    );
                                }
                            } else {
                                return PriceData(
                                    4.729321e6, 0, 0.077562793638189589e18, 4.189464e6, 0, 0.088139538225215433e18, 1e18
                                );
                            }
                        } else {
                            if (price < 10.37089e6) {
                                return PriceData(
                                    10.37089e6, 0, 0.035714285714285712e18, 4.729321e6, 0, 0.077562793638189589e18, 1e18
                                );
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
                                        0.237671e6,
                                        0.20510144474217018e18,
                                        2.337718072004858261e18,
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
                                        0.292771e6,
                                        0.242322122805021467e18,
                                        2.196897480682568293e18,
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
                                        0.356373e6,
                                        0.286297404070204931e18,
                                        2.061053544007124483e18,
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
                                        0.427871e6,
                                        0.338253076642491657e18,
                                        1.92831441898410505e18,
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
                                        0.50596e6,
                                        0.399637377885741607e18,
                                        1.796709969924970451e18,
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
                                        0.588821e6,
                                        0.472161363286556723e18,
                                        1.664168452923131536e18,
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
                                        0.67456e6,
                                        0.55784660123648e18,
                                        1.52853450260679824e18,
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
                                        0.76195e6,
                                        0.659081523200000019e18,
                                        1.387629060213009469e18,
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
                                        0.775161e6,
                                        0.675729049060283415e18,
                                        1.365968375000512491e18,
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
                                        0.785842e6,
                                        0.689449085869078049e18,
                                        1.34838993014876074e18,
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
                                        0.796558e6,
                                        0.703447694999569495e18,
                                        1.330697084427678423e18,
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
                                        0.806314e6,
                                        0.716392959999999968e18,
                                        1.314544530202049311e18,
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
                                        0.812711e6,
                                        0.724980335957853717e18,
                                        1.303936451137418295e18,
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
                                        0.82354e6,
                                        0.73970037338828043e18,
                                        1.285944077302980215e18,
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
                                        0.839894e6,
                                        0.762342714347103767e18,
                                        1.258720525989716954e18,
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
                                        0.850882e6,
                                        0.777821359399146761e18,
                                        1.240411002374896432e18,
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
                                        0.856405e6,
                                        0.785678140807218983e18,
                                        1.231207176501035727e18,
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
                                        0.867517e6,
                                        0.801630589539045979e18,
                                        1.212699992596070864e18,
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
                                        0.878727e6,
                                        0.817906937597230987e18,
                                        1.194058388444914964e18,
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
                                        0.890047e6,
                                        0.834513761450087599e18,
                                        1.17528052342063094e18,
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
                                        0.898085e6,
                                        0.846400000000000041e18,
                                        1.161985895520041945e18,
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
                                        0.913079e6,
                                        0.868745812768978332e18,
                                        1.137310003616810228e18,
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
                                        0.924827e6,
                                        0.88638487171612923e18,
                                        1.118115108274055913e18,
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
                                        0.936756e6,
                                        0.90438207500880452e18,
                                        1.09877953361768621e18,
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
                                        0.947076e6,
                                        0.92000000000000004e18,
                                        1.082198372170484424e18,
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
                                        0.955039e6,
                                        0.932065347906990027e18,
                                        1.069512051592246715e18,
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
                                        0.967525e6,
                                        0.950990049900000023e18,
                                        1.049824804368118425e18,
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
                                        0.980283e6,
                                        0.970299000000000134e18,
                                        1.029998108905910481e18,
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
                                        1.006679e6,
                                        1.010000000000000009e18,
                                        0.990033224058159078e18,
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
                                        1.020319e6,
                                        1.030300999999999911e18,
                                        0.970002111104709575e18,
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
                                        1.033686e6,
                                        1.050000000000000044e18,
                                        0.950820553711780869e18,
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
                                        1.041574e6,
                                        1.061520150601000134e18,
                                        0.93971807302139454e18,
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
                                        1.056342e6,
                                        1.082856705628080007e18,
                                        0.919376643827810258e18,
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
                                        1.070147e6,
                                        1.102500000000000036e18,
                                        0.900901195775543062e18,
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
                                        1.079529e6,
                                        1.115668346665316557e18,
                                        0.888649540545595529e18,
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
                                        1.104151e6,
                                        1.149474213237622333e18,
                                        0.857683999872391523e18,
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
                                        1.112718e6,
                                        1.160968955369998667e18,
                                        0.847313611512600207e18,
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
                                        1.130452e6,
                                        1.184304431372935618e18,
                                        0.826506641040327228e18,
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
                                        1.149062e6,
                                        1.208108950443531393e18,
                                        0.805619727489791271e18,
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
                                        1.158725e6,
                                        1.22019003994796682e18,
                                        0.795149696605042422e18,
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
                                        1.178832e6,
                                        1.244715859750920917e18,
                                        0.774163996557160172e18,
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
                                        1.200076e6,
                                        1.269734648531914534e18,
                                        0.753128441185147435e18,
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
                                        1.222589e6,
                                        1.295256314967406119e18,
                                        0.732057459169776381e18,
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
                                        1.246507e6,
                                        1.321290966898250874e18,
                                        0.710966947125877935e18,
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
                                        1.264433e6,
                                        1.340095640624999973e18,
                                        0.695987932996588454e18,
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
                                        1.285375e6,
                                        1.361327404486234682e18,
                                        0.67933309721453039e18,
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
                                        1.313542e6,
                                        1.38869008531640814e18,
                                        0.658273420002602916e18,
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
                                        1.333292e6,
                                        1.407100422656250016e18,
                                        0.644361360672887962e18,
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
                                        1.359692e6,
                                        1.430768783591580551e18,
                                        0.626781729444674585e18,
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
                                        1.41124e6,
                                        1.474122508503188822e18,
                                        0.595478226183906334e18,
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
                                        1.42978e6,
                                        1.488863733588220883e18,
                                        0.585100335536025584e18,
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
                                        1.636249e6,
                                        1.628894626777441568e18,
                                        0.493325115988533236e18,
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
                                        1.974398e6,
                                        1.79585632602212919e18,
                                        0.400069510798421513e18,
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
                                        2.505865e6,
                                        1.97993159943939756e18,
                                        0.316916199929126341e18,
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
                                        3.346057e6,
                                        2.182874588381935599e18,
                                        0.246470170347584949e18,
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
                                        4.660591e6,
                                        2.406619233691083881e18,
                                        0.189535571483960663e18,
                                        3.931396e6,
                                        2.292018317801032268e18,
                                        0.216340086006769544e18,
                                        1e18
                                    );
                                } else {
                                    return PriceData(
                                        10.709509e6,
                                        3e18,
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
