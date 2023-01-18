# Wells

A [{Well}](/src/Well.sol) is a constant function AMM that allows the provisioning of liquidity into a single pooled on-chain liquidity position.

Each Well is defined by its Tokens, Well function, and Pump.
- The **Tokens** define the set of ERC-20 tokens that can be exchanged in the Well.
- The **Well function** defines an invariant relationship between the balances of the tokens in the Well and the number of LP tokens. See [{IWellFunction}](/src//interfaces/IWellFunction.sol).
- The **Pump** is an on-chain oracles that is updated upon each interaction with the Well. See [{IPump}](/src/interfaces/IPump.sol).

A Well's Tokens, Well function, and Pump are stored as immutable variables during Well construction to prevent unnessary SLOAD calls during operation.

Wells support swapping, adding liquidity, and removing liquidity in balanced or imbalanced proportions.

Wells are stateless beyond the issuance of an ERC-20 LP token. The balance of tokens in the Well is read directly from each token's [{IERC20-balanceOf}](/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol) method. Well functions and Pumps can independently choose to be stateful or stateless.

Including a Pump is optional. Only 1 Pump can be attached to a Well, but a Pump can call other Pumps, allowing multiple Pumps to be used.

Each Well implements ERC-20, ERC-2612 and the [{IWell}](/src/interfaces/IWell.sol) interface.

## Motivation

Allowing composability of the pricing function and oracle at the Well level is a deliberate design decision with significant implications. 

In particular, a standard AMM interface invoking composable components allows for developers to iterate upon the underlying pricing functions and oracles, which greatly impacts gas and capital efficiency. 

However, this architecture shifts much of the attack surface area to the Well's components. Users of Wells should be aware that anyone can deploy a Well with malicious components, and that new Wells SHOULD NOT be trusted without careful review. This understanding is particularly important in the DeFi context in which Well data may be consumed via on-chain registries or off-chain indexing systems.

The Wells architecture aims to outline a simple interface for composable AMMs and leave the process of evaluating a given Well's trustworthiness as the responsibility of the user. To this end, future work may focus on development of on-chain Well registries and factories which create or highlight Wells composed of known components.

An example factory implementation is provided in [{Auger}](/src/Auger.sol) without any opinion regarding the trustworthiness of Well functions and the Pumps using it. Wells are not required to be deployed via this mechanism.