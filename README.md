# Wells
A Well serves as an constant function AMM allowing the provisioning of liquidity into a single pooled on-chain liquidity position.

Each Well has tokens, a pricing function, and a pump.
- Tokens defines the set of tokens that can be exchanged in the pool.
- The pricing function defines an invariant relationship between the balances of the tokens in the pool and the number of LP tokens. See {IWellFunction}
- Pumps are on-chain oracles that are updated every time the pool is interacted with. See {IPump}. Including a Pump is optional. Only 1 Pump can be attached to a Well, but a Pump can call other Pumps, allowing multiple Pumps to be used.

A Well's tokens, well function and pump are stored as immutable variables to prevent unnessary SLOAD calls.
