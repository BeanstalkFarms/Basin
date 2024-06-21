<img src="https://github.com/BeanstalkFarms/Beanstalk-Brand-Assets/blob/main/basin/basin(green)-512x512.png" alt="Basin logo" align="right" width="120" />

# Basin

Code Version: `1.0.0` <br>
Whitepaper Version: `1.0.0`

<img src="https://github.com/BeanstalkFarms/Beanstalk-Brand-Assets/blob/main/multi-flow/512x512-MF.png" alt="Multi Flow logo" align="right" width="60" />

### Multi Flow

The Multi Flow Pump implementation is also included in this repository at [MultiFlowPump.sol](/src/pumps/MultiFlowPump.sol).

Code Version: `1.0.0` <br>
Whitepaper Version: `1.0.0`

## About

Basin is a composable EVM-native decentralized exchange protocol.

- [Audits](#audits)
- [Documentation](#documentation)
    - [Motivation](#motivation)
- [License](#license)

## Audits

* [Cyfrin Basin Audit](https://basin.exchange/cyfrin-basin-audit.pdf)
* [Halborn Basin Audit](https://basin.exchange/halborn-basin-audit.pdf)

## Documentation

* [Basin Whitepaper](https://basin.exchange/basin.pdf)
* [Multi Flow Whitepaper](https://basin.exchange/multi-flow-pump.pdf)
* [Basin Docs](https://docs.basin.exchange)

A [{Well}](/src/Well.sol) is a constant function AMM that allows the provisioning of liquidity into a single pooled on-chain liquidity position.

Each Well is defined by its Tokens, Well function, and Pump.
- The **Tokens** define the set of ERC-20 tokens that can be exchanged in the Well.
- The **Well function** defines an invariant relationship between the Well's reserves and the supply of LP tokens. See [{IWellFunction}](/src//interfaces/IWellFunction.sol).
- **Pumps** are an on-chain oracles that are updated upon each interaction with the Well. See [{IPump}](/src/interfaces/IPump.sol).

A Well's tokens, Well function, and Pump are stored as immutable variables during Well construction to prevent unnecessary SLOAD calls during operation.

Wells support swapping, adding liquidity, and removing liquidity in balanced or imbalanced proportions.

Wells maintain two components of state:
- a balance of tokens received through Well operations ("reserves")
- an ERC-20 LP token representing pro-rata ownership of the reserves

Well functions and Pumps can independently choose to be stateful or stateless.

Including a Pump is optional.

Each Well implements ERC-20, ERC-2612 and the [{IWell}](/src/interfaces/IWell.sol) interface.

### Motivation

Allowing composability of the pricing function and oracle at the Well level is a deliberate design decision with significant implications. 

In particular, a standard AMM interface invoking composable components allows for developers to iterate upon the underlying pricing functions and oracles, which greatly impacts gas and capital efficiency. 

However, this architecture shifts much of the attack surface area to the Well's components. Users of Wells should be aware that anyone can deploy a Well with malicious components, and that new Wells SHOULD NOT be trusted without careful review. This understanding is particularly important in the DeFi context in which Well data may be consumed via on-chain registries or off-chain indexing systems.

The Wells architecture aims to outline a simple interface for composable AMMs and leave the process of evaluating a given Well's trustworthiness as the responsibility of the user. To this end, future work may focus on development of on-chain Well registries and factories which create or highlight Wells composed of known components.

An example factory implementation is provided in [{Aquifer}](/src/Aquifer.sol) without any opinion regarding the trustworthiness of Well functions and the Pumps using it. Wells are not required to be deployed via this mechanism.

## License

[MIT](https://github.com/BeanstalkFarms/Basin/blob/master/LICENSE.txt)
