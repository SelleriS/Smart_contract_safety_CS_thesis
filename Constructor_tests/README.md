# Move constructor test case

## Goal 
This research aims to compare Move to Solidity and see if Move can solve the most common vulnerabilities found in Solidity. The most common Solidity bugs are replicated using the Move programming language and the Aptos Move framework to see if they are still prevalent or caught during compilation or runtime.

This particular experiment is created to test if the same problems related to the incorrect implementation of a constructor in Solidity are also present in Move. 

The [Crowdfunding contract](../Crowdfunding_contract/sources/CrowdFunding.move) from the [CrowdFunding](../Crowdfunding_contract) directory is used for this test. The contract has been slightly altered by removing a check in the *initialize_crowdfunding* function. This function serves as a type of constructor for the contract. This is because the Move language does not have the notion of a constructor. The removed line ensured that the initialisation function could only be called by the same account as the account which stored the module (contract). This experiment aims to see if this opens the contract up to the same constructor-related vulnerabilities common in Solidity. 

## How to run the experiment?
1. Download the [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)
2. Download the [Unprotected Tests](../Unprotected_tests/) directory
3. <code>cd</code> into the directory
4. Run the following commands:

 ```
 aptos init
 aptos move compile --named-addresses testing=default aptos move test --named-addresses testing=default
 ```

The Aptos CLI executable is saved in a *bin* folder in the home directory. An alias was created for the Aptos CLI to make the commands more readable. If the reader chooses not to create an alias, run the previous commands as follows: e.g. <code>~/bin/aptos init</code> instead of just using <code>aptos init</code>.

## Findings
The [CrowdfundFunding Tests](/tests/CrowdFundingTests.move) script contains two similar test functions, but they have different reasoning behind them. Both tests follow the following sequence:
1. Both the fund and two donor accounts are created (the fund account is the account that contains the CrowdFunding module)
2. Coins of the type *FakeMoney* are created
3. 500 *FakeMoney* coins are allocated to each donor
4. The crowdfunding contract is initialised by <code>donor_a</code> with a deadline of 1 minute and a funding goal of 300 *FakeMoney* coins
5. <code>donor_a</code> and <code>donor_b</code> each donate 200 coins to the contract => GOAL is met 

Step 5 of both tests differs slightly. In the first test, <code>donor_b</code> is aware that the contract has been initialised by <code>donor_a</code> and sends the donation to the <code>donor_a</code>'s address. This causes no problems, and after the deadline has passed, <code>donor_a</code> can claim the funds without any errors. The fact that <code>donor_a</code> was able to claim the funds is tested by checking <code>donor_a</code>'s balance.

In the second test, <code>donor_b</code> does not know that the contract has been initialised by <code>donor_a</code> instead of the owner of the module. Thus when <code>donor_b</code> tries to donate the money to the contract, a <code>CAMPAIGN_DOES_NOT_EXIST</code> error is thrown.

## Discussion
In the first test, <code>donor_a</code> was able to take over the contract by initialising the contract before anyone else. This meant that <code>donor_a</code> is now the contract owner and thus can claim the funds once a crowdfunding goal is met and the deadline has passed. No errors will be thrown because no rules were broken. This is due to lousy access control in the contract's initialisation function. There is no check to ensure that only the module owner can initialise the contract. This is similar to the [Unprotected Test](../Unprotected_tests/), but this time it is the initialisation function that is unprotected. 

The second test proves the same vulnerability and outcome as the first, namely that <code>donor_a</code> can take over the contract. However, the idea behind it is different. In the second test, <code>donor_b</code> is unaware that the contract has been initialsed by <code>donor_a</code>. This causes <code>donor_b</code> to donate to the wrong address, and thus his donation fails because it is trying to donate to an address that does not contain a crowdfunding. This second test is an example of a *Denial of Service attack* because it not only shows that someone could take over a contract and steal its funds but also how someone could disrupt the regular business of a contract and thus cause a *Denial of Service*. 

## Conclusion
A Move contract that does not implement access control is similar to a Solidity contract that does not. Writing a contract in the Move language does not automatically prevent access control vulnerabilities. Developers must take matters into their own hands and manually implement checks to prevent unauthorised parties from calling certain functions. This logic is essential for all functions in the contract, especially the initialisation function, which serves as a constructor in Move. If an attacker can exploit the initialisation function, he could take over the entire contract.

## Sources
1. [Pontem Network Docs](https://docs.pontem.network/02.-move-language/lang)
2. [Diem Move Docs](https://diem.github.io/move/introduction.html)
3. [Move Fast & Break Things Part 1: Move Security (Aptos)](https://www.zellic.io/blog/move-fast-and-break-things-pt-1)
4. [Move language Tutorial](https://github.com/move-language/move/tree/main/language/documentation/tutorial)
5. [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)