#!/bin/bash

# Private key for 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
export PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

forge script "scripts/$1.s.sol:Deploy$1" \
  --fork-url http://localhost:8545 \
  --broadcast \
  --sender "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"