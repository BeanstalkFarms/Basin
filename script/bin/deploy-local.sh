#!/bin/bash

# Private key for test account: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
# NOTE: This is a test account provided by Hardhat/Forge for testing. It should
# never be used in production.
export PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

forge script "script/deploy/$1.s.sol:Deploy$1" \
  --fork-url http://localhost:8545 \
  --broadcast \
  --sender "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"