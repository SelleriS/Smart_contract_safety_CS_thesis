# Move unprotected test case

## Goal 
This research aims to compare Move to Solidity and see if Move can solve the most common vulnerabilities found in Solidity. The most common Solidity bugs are replicated using the Move programming language and the Aptos Move framework to see if they are still prevalent or caught during compilation or runtime.

This particular experiment is created to test if the Move VM allows unprotected functions and thus allows bugs related to them.

The [Crowdfunding contract](../Crowdfunding_contract/sources/CrowdFunding.move) from the [CrowdFunding](../Crowdfunding_contract) directory is used for this test. The contract has been slightly altered by removing a check in the *claimFunds* function. The removed line ensured that the function could only be called by the owner of the contract. The goal is to see if this renders the function unprotected and opens the contract to related vulnerabilities.

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
The test simulates the following:
1. Both the fund and two donor accounts are created (the fund account represents the owner of the contract)
2. Coins of the type *FakeMoney* are created
3. 500 *FakeMoney* coins are allocated to each donor
4. The crowdfunding contract is initialised with a deadline of 1 minute and a funding goal of 300 *FakeMoney* coins
5. <code>donor_b</code> donates 400 coins to the contract => GOAL is met 
6. <code>donor_a</code> tries to claim the funds

The last step of the test function in the CrowdFundingTest script is to check if <code>donor_a</code> was successful in claiming the funds by checking if its *FakeMoney* balance is equal to or lower than 500 *FakeMoney* coins. This test fails and throws the <code>ANYONE_CAN_CLAIM_DONATIONS</code> error. The test function expected this error, and thus the test passed successfully. 

## Discussion
The fact that the <code>test_only_owner_can_claim</code> test function passes successfully means that anyone, in this case <code>donor_a</code>, can claim the funds of the *CrowdFunding* contract. This test proves that the <code>claimFunds</code> function is rendered unprotected by removing the line that checks if the function is called by the owner. Consequently, the contract is open to vulnerabilities related to unprotected contracts, similar to Solidity contracts that do not implement access control. 

This outcome is logical because the Move VM can not know what the developers' access control policy is and thus can not automatically enforce it. The developer's job is to manually implement the access control policy to ensure that vulnerabilities related to unprotected functions are mitigated.

## Conclusion
A Move contract that does not implement access control is similar to a Solidity contract that does not. Writing a contract in the Move language does not automatically prevent access control vulnerabilities. Developers must take matters into their own hands and manually implement checks to prevent unauthorised parties from calling certain functions.

## Sources
1. [Pontem Network Docs](https://docs.pontem.network/02.-move-language/lang)
2. [Diem Move Docs](https://diem.github.io/move/introduction.html)
3. [Move Fast & Break Things Part 1: Move Security (Aptos)](https://www.zellic.io/blog/move-fast-and-break-things-pt-1)
4. [Move language Tutorial](https://github.com/move-language/move/tree/main/language/documentation/tutorial)
5. [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)