 Move passing signer test case

## Goal 
This research aims to compare Move to Solidity and see if Move can solve the most common vulnerabilities found in Solidity. The most common Solidity bugs are replicated using the Move programming language and the Aptos Move framework to see if they are still prevalent or caught during compilation or runtime.

This experiment is created to test different features of the Crowdfunding contract on the Aptos Move Devnet. The goal was to explore how to deploy a module on the Devnet and how to interact with it. It allowed to test certain hypothesis about how two different contracts on the Aptos Devnet interact and how they can be updated. Additionally, this experiment was a way to think about how certain vulnerabilities could be introduced in a module by exploiting features of the Move framework. 

The [Crowdfunding contract](../Crowdfunding_contract/sources/CrowdFunding.move) from the [PassSigner](../PassSigner_tests) directory is used for this test. The contract has been modified in different ways:
- First, by ...
- Secondly, by ...

## How to setup the experiment?
1. Download the [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)
2. Download the [Wrong Interface Tests](../WrongInterface_tests/) directory
3. <code>cd</code> into the [WI_Crowdfunding](../WI_Crowdfunding/) directory
4. Run the following commands to publish the *Crowdfunding* module:

 ```
    aptos init
    aptos move compile
    aptos move publish
 ```
5. Once the module is published, run the following commands to publish the *FlaggingDonor* module:
 ```
    cd ..
    cd WI_Flagging
    aptos init
 ```
Now that the both modules are published, the experimentation can begin 

The Aptos CLI executable is saved in a *bin* folder in the home directory. An alias was created for the Aptos CLI to make the commands more readable. If the reader chooses not to create an alias, run the previous commands as follows: e.g. <code>~/bin/aptos init</code> instead of just using <code>aptos init</code>.

## How to experiment?
Start by creating a new account that will be used by 
 ```
    cd ..
    mkdir Account2
    cd Account2
    aptos init
 ```

 ```
    FUNDADDRESS=0x815e0c554f2cdee0ff4e249727ba275952b30a09a11ba47d251a2fd2a5e28172

    aptos move run --function-id $FUNDADDRESS::crowdfunding::initialize_crowdfunding --args u64:"30000000" u64:"10" --type-args 0x1::aptos_coin::AptosCoin

    aptos move run --function-id $FUNDADDRESS::crowdfunding::donate --args address:$FUNDADDRESS u64:"10000000" --type-args 0x1::aptos_coin::AptosCoin

    aptos move run --function-id $FUNDADDRESS::crowdfunding::claimFunds --args address:$FUNDADDRESS --type-args 0x1::aptos_coin::AptosCoin

    aptos move run --function-id $FUNDADDRESS::crowdfunding::selfDestruct --args address:$FUNDADDRESS --type-args 0x1::aptos_coin::AptosCoin

 ```

*FUNDADDRESS* should be equal to the address of the fund, which is the address of the account that deployed the CrowdFunding module. This address was created and returned by the <code>aptos init</code> command.


## Findings
The test simulates the following:
1. Fund is initialized
2. Fund account donates to fund
3. Donor_1 donates to fund
4. At deadline: 
    1. If goal reached => claimFunds and check account balance in wallet
    2. If goal not reached => get Refund and check account balance in wallet
5. Check if CrowdFunding object has been removed in Fund account
6. Repeat any other scenario


## Discussion


## Conclusion


## Sources
1. [Pontem Network Docs](https://docs.pontem.network/02.-move-language/lang)
2. [Diem Move Docs](https://diem.github.io/move/introduction.html)
3. [Move Fast & Break Things Part 1: Move Security (Aptos)](https://www.zellic.io/blog/move-fast-and-break-things-pt-1)
4. [Move language Tutorial](https://github.com/move-language/move/tree/main/language/documentation/tutorial)
5. [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)
6. [Aptos Module/ Resource Explorer](https://aptos-module-explorer.vercel.app/)


