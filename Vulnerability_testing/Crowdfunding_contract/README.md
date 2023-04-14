# Move crowdfunding smart contract

## Goal 
The goal of this project is to port a crowdfunding smart contract from Solidity to Move and research the workflow and programming logic that is needed to achieve this. 

The smart contract that was ported is taken from the paper: *The Next 700 Smart Contract Languages* - *Ilya Sergey*

## Files
- The ported smart contract can be found in [CrowdFunding.move](sources/CrowdFunding.move)
- Tests developed to test the different features of the contract can be found in [CrowdFundingTests.move](tests/CrowdFundingTests.move)

## Findings

### Solidity vs Move in terms of logic
There is a major difference in how resources are handled in both languages.
    => **Account centric (Solidity) vs Bank centric (Move)**
...
### Solidity vs Move in terms of workflow
...
### Move intricacies
...


## Sources
1. [Pontem Network Docs](https://docs.pontem.network/02.-move-language/lang)
2. [Pontem Network Playground](https://playground.pontem.network)
3. [Diem Move Docs](https://diem.github.io/move/introduction.html)
4. [Move language Tutorial](https://github.com/move-language/move/tree/main/language/documentation/tutorial)
5. [The next 700 Smart Contract Languages](https://link.springer.com/chapter/10.1007/978-3-031-01807-7_3)
