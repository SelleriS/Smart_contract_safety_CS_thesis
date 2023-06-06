# Solidity Contract translation to Move
This directory contains three Move translations of representative Solidity smart contracts. The translation is accomplished using a systematic process in order to identify common translation patterns. These patterns are then used to derive basic translation rules, which can be used in future work to create an automated tool to translate Solidity contracts to Move. 

For this experiment, three representative smart contract types are chosen:
- Automatic Market Maker (AMM)
-  Decentralised Autonomous Organisation (DAO)
- Supply Chain Tracker (SCT)

These types are chosen because their underlying concepts are prevalent in Web3. Another reason for choosing them is because they are distinct from each other. They thus have different goals and priorities and cover different underlying Web3 concepts.

## Goal 
The goal of these translation experiments was to identify key Solidity concepts and how they can be represented in Move. The ultimate goal is to be able to define rules to automate the porting process in the future. These experiments also tell us something about Move's expressivity by showing if Move can capture the most common Solidity coding patterns.

## Methodology
The steps followed to translate Solidity contracts systematically to Move are the following:
1. Identify and translate state variables
2. Identify and translate structs
3. Identify and translate functions and modifiers
4. Identify and translate events

## Identified rules
The following translation rules are defined as a first step towards developing an automated Solidity-to-Move translator.
1. State variables
    1. If the Solidity contract has state variables, create a resource struct to keep track of the state of the module in Move
        1. The struct should have the `key` ability.
        2. The struct must at least have the same number of fields as the number of state variables in Solidity minus the variables of the form `mapping(address => value)`.
    2. A separate resource struct must be defined for every state variable of the form `mapping(address => value)`.
        1. It may be possible to merge of few of the fields together.

2. Structs
    1. Solidity structs are translated to Move structs with the `store` ability.
        2. If the Solidity struct contains an Ether value field, it must be translated to a Move field holding resources of the type `Coin<CoinType>`. The `CoinType` generic type parameter must also be included in the signature of the struct.

3. Functions & modifiers
    1. Functions are translated as is.
        1. `external` and `public` Solidity functions become `public entry` functions in Move. This ensures that all functions are callable in a transaction.
        2. All `private` functions stay `private`.
        3. `internal` functions become `public(friend)` functions.
        4. `payable` functions are translated as normal Move functions that take an extra argument in the signature. This extra argument is an integer that signifies the amount to be transferred. The transfer happens explicitly inside the function. 
        5. Keep in mind that inheritance does not exist in Move. So code duplication may be necessary.   
    1. Modifiers must be translated to functions.
        1. These functions must be called inside the to-be-modified Move function.
        2. These functions take a `signer` object reference as a first argument if they have to perform access control.

4. Events
    1. Solidity `event` objects become structs in Move.
        1. The event structs must have the `drop` and `store` ability.
        2. The event structs must be stored inside an `EventHandler` inside another struct.
        3. The event struct must be emitted using the `EventHandler`.


## Testing the code
The code can be tested using the included test files which contain basic test scenarios, or by using a resource explorer such as [8.](https://aptos-module-explorer.vercel.app/), a wallet (e.g. Pontem wallet), and the Aptos CLI. You can then deploy the contract, load up your account using a faucet and send out manual transactions to the deployed contract. The transactions will be viewable using the resource explorer. This will show you the resources that have been added to an account address. In the case of the AMM contract the Move Prover could also be used because `spec`blocks have been included in the code. 

## Conclusion
The three contracts were manually translated to Move to identify common translation patterns. The translation process was refined along the way, and a methodology was defined to translate contracts and identify patterns systematically. The identified patterns served to formulate translation rules, which in turn, can be used to define a basic mapping from Solidity code to Move code forming the basis of what could become a complete translation tool in the future.

## Sources
1. [Pontem Network Docs](https://docs.pontem.network/02.-move-language/lang)
2. [Diem Move Docs](https://diem.github.io/move/introduction.html)
3. [AMM Solidity contract](https://solidity-by-example.org/defi/constant-product-amm/)
4. [DAO Solidity contract](https://github.com/blockchainsllc/DAO/blob/develop/DAO.sol)
5. [Supply Chain Solidity contract](https://github.com/SelleriS/UD_SupplyChainProject)
6. [Move language Tutorial](https://github.com/move-language/move/tree/main/language/documentation/tutorial)
7. [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)
8. [Aptos Module/ Resource Explorer](https://aptos-module-explorer.vercel.app/)
