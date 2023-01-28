# Move reentrancy test case

## Goal 
This research aims to compare Move to Solidity and see if Move can solve the most common vulnerabilities found in Solidity. The most common Solidity bugs are replicated using the Move programming language and the Aptos Move framework to see if they are still prevalent or caught during compilation or runtime.

This particular experiment is created to test if the Move VM allows reentrancy attacks which is one of the most infamous vulnerabilities in Solidity.

The [Crowdfunding contract](../Crowdfunding_contract/sources/CrowdFunding.move) from the [CrowdFunding](../Crowdfunding_contract) directory is used for this test. The contract has been slightly altered by adding an external call in the *getRefund* function. This external call is to the *getRefund_callback* function defined in a newly defined module called *callback_crowdfunding*. This new module is defined at address *testing2*, a different address than the original *crowdfunding* contract, which is defined at address *testing*. 

## How to run the experiment?
1. Download the [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)
2. Download the [Reentrancy Tests](../Reentrancy_tests/) directory
3. <code>cd</code> into the directory
4. Run the following commands:

 ```
 aptos init
 aptos move compile --named-addresses testing=default 
 ```

The Aptos CLI executable is saved in a *bin* folder in the home directory. An alias was created for the Aptos CLI to make the commands more readable. If the reader chooses not to create an alias, run the previous commands as follows: e.g. <code>~/bin/aptos init</code> instead of just using <code>aptos init</code>.

## Findings
In this experiment, the *getRefund* function will do an external call to the *getRefund_callback* function. The *getRefund_callback* function will, in turn, call back the *getRefund* function to call the getRefund function multiple times. However, this setup will not run because it will not compile.


## Discussion
The reason why this experiment will not compile is that the Move compiler does not allow circular dependencies. This refers to the fact that the *crowdfunding* module states that it *uses* the *callback_crowdfunding* module, and the *callback_crowdfunding* module states that it *uses* the *crowdfunding* module. This is a circular relationship, and it is not allowed by the Move compiler.

The reason why the Move compiler catches these circular dependencies is that all external modules called must be predeclared and imported and cannot be dynamically computed at runtime. This is due to Move offering *No Dynamic dispatch*, which makes Move resolve and link functions at compile time [3]. 

## Conclusion
The Move compiler does a cyclic dependency check during the linking phase at compile time, which will catch most, if not all, cyclic dependencies and, thus, prevent reentrancy attacks to a great extent.

## Sources
1. [Pontem Network Docs](https://docs.pontem.network/02.-move-language/lang)
2. [Diem Move Docs](https://diem.github.io/move/introduction.html)
3. [Move Fast & Break Things Part 1: Move Security (Aptos)](https://www.zellic.io/blog/move-fast-and-break-things-pt-1)
4. [Move language Tutorial](https://github.com/move-language/move/tree/main/language/documentation/tutorial)
5. [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)