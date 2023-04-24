# Solidity Contract porting to Move
This directory contains three Move projects that have been ported from Solidity. The three projects are popular Blockchain application ideas, namely:
- Supplychain
- DAO
- Automatic Market Maker (AMM)

## Goal 
The goal of these porting experiments was to identify key Solidity concepts and how they can be represented in Move. The ultimate goal is to be able to define rules to automate the porting process in the future. 

## Methodology
1. Look at the contract as a whole
    1. Identify the state variables
    2. Identify the functions and function modifiers

## Sources
1. [Pontem Network Docs](https://docs.pontem.network/02.-move-language/lang)
2. [Diem Move Docs](https://diem.github.io/move/introduction.html)
3. [AMM Solidity contract](https://solidity-by-example.org/defi/constant-product-amm/)
4. [DAO Solidity contract](https://github.com/blockchainsllc/DAO/blob/develop/DAO.sol)
5. [Supply Chain Solidity contract](https://github.com/SelleriS/UD_SupplyChainProject)
6. [Move language Tutorial](https://github.com/move-language/move/tree/main/language/documentation/tutorial)
7. [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)
8. [Aptos Module/ Resource Explorer](https://aptos-module-explorer.vercel.app/)
