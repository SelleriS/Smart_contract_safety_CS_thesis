# Move passing signer test case

## Goal 
This research aims to compare Move to Solidity and see if Move can solve the most common vulnerabilities found in Solidity. The most common Solidity bugs are replicated using the Move programming language and the Aptos Move framework to see if they are still prevalent or caught during compilation or runtime.

This particular experiment is created to test if the Move VM allows the signer object to be passed around between modules that are saved at different addresses

The [Crowdfunding contract](../Crowdfunding_contract/sources/CrowdFunding.move) from the [CrowdFunding](../Crowdfunding_contract) directory is used for this test. The contract has been slightly altered by calling the external function *addFlag* in the *donate* function. This external function takes two arguments, namely a signer object that represents a crowdfunding donor and an amount that represents the amount donated. It will check if the donation is above 300 and if so, it will attribute a *BigDonorFlag* resource to the signer's account. Both the *addFlag* function as the *BigDonorFlag* resource are part of a separate module named *flagging_donor* that is saved under the address *@testing2*.

## How to run the experiment?
1. Download the [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)
2. Download the [Unprotected Tests](../Unprotected_tests/) directory
3. <code>cd</code> into the directory
4. Run the following commands:

 ```
 aptos init
 aptos move compile --named-addresses testing=default 
 aptos move test --named-addresses testing=default
 ```

The Aptos CLI executable is saved in a *bin* folder in the home directory. An alias was created for the Aptos CLI to make the commands more readable. If the reader chooses not to create an alias, run the previous commands as follows: e.g. <code>~/bin/aptos init</code> instead of just using <code>aptos init</code>.

## Findings
The test simulates the following:
1. Both the fund and two donor accounts are created (the fund account represents the owner of the contract)
2. Coins of the type *FakeMoney* are created
3. 500 *FakeMoney* coins are allocated to each donor
4. The crowdfunding contract is initialised with a deadline of 1 minute and a funding goal of 300 *FakeMoney* coins
5. <code>donor_a</code> donates 400 coins to the contract
6. <code>donor_b</code> donates 200 coins to the contract

The last step of the test function in the *CrowdFundingTest* script is to check if <code>donor_a</code> has been flagged for being a big donor by receiving the *BigDonorFlag* resource. When testing this, it shows that the *BigDonorFlag* resource is published under <code>donor_a</code>'s account. 

## Discussion
The fact that the <code>test_pass_signer</code> test function passes successfully means that a signer object can be passed around between modules. Even if the modules are stored under different addresses. This can be a used to exploit a contract or account if the contract in question calls external functions from modules it does not fully thrust, and passes a signer object to them. The untrustworthy modules can then manipulate aspects of the account like registering it for certain types of coins which would open up the account to forced token reception. 


## Conclusion
It is important to not randomly pass signer objects to external functions if they are not fully trustworthy. The move VM does not prevent it, but it can have unwanted consequences if a signer object falls in the wrong hands.

## Sources
1. [Pontem Network Docs](https://docs.pontem.network/02.-move-language/lang)
2. [Diem Move Docs](https://diem.github.io/move/introduction.html)
3. [Move Fast & Break Things Part 1: Move Security (Aptos)](https://www.zellic.io/blog/move-fast-and-break-things-pt-1)
4. [Move language Tutorial](https://github.com/move-language/move/tree/main/language/documentation/tutorial)
5. [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)