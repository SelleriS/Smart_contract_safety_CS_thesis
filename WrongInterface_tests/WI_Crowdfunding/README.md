# Move wrong interface test case

## Goal 
This experiment is created to test different features of the Crowdfunding contract on the Aptos Move Devnet. The goal was to explore how to deploy a module on the Devnet and how to interact with it. It allowed to test certain hypothesis about how two different contracts on the Aptos Devnet interact and how they can be updated. Additionally, this experiment was a way to think about how certain vulnerabilities could be introduced in a module by exploiting features of the Move framework. 

The [Crowdfunding contract](../Crowdfunding_contract/sources/CrowdFunding.move) from the [PassSigner](../PassSigner_tests) directory is used for this test. The contract has been modified in different ways:
1. The <code>flagging_donor</code> module has been seperated into a different file in its own package called *WIFlagging2* with its own <code>Move.toml</code> file. A dependency to the new package is added in the *Crowdfunding package's <code>Move.toml</code> file together with a path to the <code>flagging_donor</code>'s source file (which in this case is a local file, but could also be a remote file with a <code>git</code> path). 
2. The <code>n_of_donors</code> field has been added to the <code>crowdfunding</code> struct to keep track of the number of donors. This means that everytime a donor donates or asks for a refund, this field is altered. 
3. The <code>selfDestruct</code> function is added to destroy the crowdFunding resource in case there are no donors and the deadline has passed. This function is used by the owner of the module to destroy the current crowdfunding and thus remove it from his account. This cleanup is necessary in case the owner want to create a new crowdfunding because an account can't hold multiple resources of the same type.
4. The <code>destroyCrowdfunding</code> helper function is added which will actually destroy the crowdfunding resource by *pattern matching*. This is the function that is called by the <code>selfDestruct</code> function. But it is also called in the <code>getRefund</code> function to destroy the crowdfunding object after the last donor has reclaimed is funds. The <code>claimFunds</code> function also calls this function as a last step to remove the crowdfunding after all resources have been claimed.
5. A check is added in the <code>donate</code> function to check if the deadline has not yet passed. This is to prevent donationas after the deadline. To achieve this, the <code>assertDeadlinePassed</code> helper function has been altered to receive an extra boolean parameter with which the user can check if the deadline has passed or if the deadline has not yet passed and throw an error if the desired scenario is not met. 

These changes were made to improve the <code>crowdfunding</code> module after testing different (edge)cases while the contract was deployed on the Aptod Devnet. Different vulnerabilities have been studied and taken into account when developing this version of the <code>crowdfunding</code> module. This makes this version of the module safer than all the other <code>crowdfunding</code> modules present in this github repository. 

## How to setup the experiment?
1. Download the [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)
2. Download the [Wrong Interface Tests](../WrongInterface_tests/) directory
3. <code>cd</code> into the [WI_Crowdfunding](../WI_Crowdfunding/) directory
4. Run the following commands to publish the <code>crowdfunding</code> module:

 ```
    aptos init
    aptos move compile
    aptos move publish
 ```
5. Once the module is published, run the following commands to publish the <code>flagging_donor</code> module:

 ```
    cd ..
    cd WI_Flagging
    aptos init
    aptos move compile
    aptos move publish
 ```

Now that the both modules are published, the experimentation can begin 

The Aptos CLI executable is saved in a <code>bin</code> folder in the home directory. An alias was created for the Aptos CLI to make the commands more readable. If the reader chooses not to create an alias, run the previous commands as follows: e.g. instead of using <code>aptos init</code>, run <code>~/bin/aptos init</code> .

## How to experiment?
Start by creating a new donor account by: 

 ```
 cd ..
 mkdir Account2
 cd Account2
 aptos init
 ```

To experiment with the modules, set up a variable equal to the account address containing the <code>crowdfunding</code> module. The <code>aptos init</code> command creates and returns this address. In this case, the variable is named <code>FUNDADDRESS</code>. 

 ```
 FUNDADDRESS=0x815e0c554f2cdee0ff4e249727ba275952b30a09a11ba47d251a2fd2a5e28172
 ```
After setting up the address, one must initialise the crowdfunding with the desired properties. To achieve this, a transaction must be sent to the blockchain. A possible initialisation transaction could look like this: 

 ```
 aptos move run --function-id $FUNDADDRESS::crowdfunding::initialize_crowdfunding --args u64:"30000000" u64:"10" --type-args 0x1::aptos_coin::AptosCoin
 ```

This transaction initialises a crowdfunding that uses APT (Aptos blockchain's native coin) as a currency, with a goal of 30.000.000 octas = 0.3 APT and a deadline of 10 minutes. This transaction must be sent by the <code>crowdfunding</code> module owner. So, it must be executed in the [WI_Crowdfunding](../WI_Crowdfunding/) directory.

After initialising the crowdfunding, one can start donating. To donate a specific sum, the following transaction can be used:

 ```
 aptos move run --function-id $FUNDADDRESS::crowdfunding::donate --args address:$FUNDADDRESS u64:"10000000" --type-args 0x1::aptos_coin::AptosCoin
 ```

This transaction will donate 10.000.000 octas = 0.1 APT to the crowdfunding. The donation will happen from the account that is currently used. The account used depends on the current directory. If one is donating from the [WI_Crowdfunding](../WI_Crowdfunding/) directory, he is donating from the funds account. If one changes the directory to, for example, *Account2*, one can donate from *Acount2*'s funds. 

One must change the directory because one needs the account credentials created using <code>aptos init</code>. These credentials are present in the <code>.aptos</code> directory in the <code>config.yaml</code> file. By calling <code>aptos init</code>, aptos will create your account and fund it. That is why one can already donate without first funding one's account using a faucet.

Depending if the funding goal is reached, a donor can ask for a refund, or the fund owner can claim the funds donated. Both of these two action can be achieved by the two transactions below. 

 ```
 aptos move run --function-id $FUNDADDRESS::crowdfunding::getRefund --args address:$FUNDADDRESS --type-args 0x1::aptos_coin::AptosCoin
 
 aptos move run --function-id $FUNDADDRESS::crowdfunding::claimFunds --args address:$FUNDADDRESS --type-args 0x1::aptos_coin::AptosCoin
 ```

The owner should delete the crowdfunding if no donations are made and the deadline is passed. Because otherwise, he can not create a new crowdfunding in the future. This can be done using the following transaction:

 ```
 aptos move run --function-id $FUNDADDRESS::crowdfunding::selfDestruct --args address:$FUNDADDRESS --type-args 0x1::aptos_coin::AptosCoin

 ```

During the experiment, the base code of both the <code>crowdfunding</code> module and the <code>flagging_donor</code> module were edited to suit the experiment. The reader could do the same and use the base code as a starting point to perform his or her own experiments comparable to the ones described below.

## Findings & Discussion
For all experiments below, both the <code>crowdfunding</code> module and the <code>flagging_donor</code> module are published under different accounts (run <code>aptos init</code>, <code>aptos move publish</code> in the respective directories to achieve this). 

### Experiment 1: Updating dependency module without publishing
1. Add a new function to the <code>flagging_donor</code> module and compile the new version of the module, but do not publish it yet. In our case, we added the <code>unFlag</code> function.
2. Use this new function in the <code>crowdfunding</code> module
3. Compile the new <code>crowdfunding</code> module => no errors
4. Publish the new <code>crowdfunding</code> module => <code>LOOK_UP_FAILED</code> error
5. Publish the new <code>flagging_donor</code> module => no errors
6. Publish the new <code>crowdfunding</code> module => no errors

The source code of dependencies should always be available locally or via git. This means the compiler has access to the dependency code at compilation time. Suppose there is an inconsistency between the dependency interface and how dependency functions are called. In that case, it will be caught by the compiler, and a compilation error will be thrown. However, if the dependency interface is edited (e.g. adding a function, editing the number of parameters in a function signature, ...) and the calling code is modified to reflect the changes made to the dependency, no compiler error will be thrown.
If the modified calling module is published while the modified dependency module is not yet published, a <code>LOOK_UP_FAILED</code> error will be thrown. This is because the dependency code still needs to be modified on the chain. The modified dependency code must also be published to solve this issue so it is on chain. 
The dependency code on the chain can be checked because the dependency address is included in the <code>Move.toml</code> file.

### Experiment 2: Removing bugs by upgrading
Before starting this experiment, a logical bug was introduced into the <code>flagging_donor</code> module. This logical error made it impossible for a donor to donate significant sums twice because the module did not check if a donor was already flagged and tried to add a second flag. In Move, it is forbidden for an account to contain two resources of the same type. This is a logic error and will thus not trigger a compiler or running time error.

1. Publish both the <code>crowdfunding</code> module and the <code>flagging_donor</code> module after introducing the error
2. Initialise crowdfunding
3. Donate a high enough sum to get flagged
4. Donate a high enough sum to get flagged => error
5. Update <code>flagging_donor</code> module to solve the logic bug (= check if an account already is flagged)
6. Publish <code>flagging_donor</code> module
7. Donate a high enough sum to get flagged => success

This proves that in Aptos Move, it is possible to upgrade a buggy contract to patch bugs and thus improve safety. The added benefit is that it is not necessary to re-publish modules that depend on the patched module for the patch to take effect. This is because the upgraded module is published under the same account and thus can be found at the same address. So, nothing has to change in the dependent modules <code>Move.toml</code> file.

### Experiment 3: Change the terms of the agreement
The previous experiment showed that it is possible to update a module while it is already published. This experiment aims to see if it is possible to take advantage of this feature by making the module unsafe. This is achieved by completely changing the terms of the agreement so the module can be exploited. This is done in the <code>crowdfunding</code> module by commenting out some checks that prevent the owner from claiming the funds before the goal is met or before the deadline has passed. 

1. Publish both the <code>crowdfunding</code> module and the <code>flagging_donor</code> module
2. Initialise crowdfunding
3. Donate one or multiple accounts but make sure not to reach the crowdfunding goal
4. Claim the funds with the owner account => error
5. Update <code>crowdfunding</code> module by commenting out the GoalReached and DeadlinePAssed checks 
6. Publish <code>crowdfunding</code> module
7. Claim the funds with the owner account => success. All funds are withdrawn even if the goal has not been met

The fact that this succeeds means that the owner of a module (= account under which the module is published) has the power to update a contract in ways that he/she sees fit. Even if it completely changes the terms of the agreement and takes advantage of the accounts interacting with it. Thus one must fully trust the owner of a module before interacting with it.

### Experiment 4: How much can one update
This experiment was conducted to see how much a function signature can change during a module update. For this, the <code>flagging_donor</code> module's <code>addFlag</code> function was altered to return a value. This was done while both modules were published.

1. Publish both the <code>crowdfunding</code> module and the <code>flagging_donor</code> module
2. Update the <code>flagging_donor</code> module's <code>addFlag</code> function to return a value
3. Compile the <code>crowdfunding</code> module => no error
4. Publish the <code>crowdfunding</code> module => <code>TYPE_MISMATCH</code> error
5. Treat the <code>addFlag</code> function's return value in the <code>crowdfunding</code> module and publish the <code>crowdfunding</code> module again => still <code>TYPE_MISMATCH</code> error
6. Publish the <code>flagging_donor</code> module => BACKWARD_INCOMPATIBLE_MODULE_UPDATE error
7. Change <code>flagging_donor</code> module's name to <code>flagging_donor2</code> module => EMODULE_MISSING error: can not delete module that was published in the same package
8. Change <code>flagging_donor2</code> module's package name => success
9. Publish the <code>crowdfunding</code> module => success
10. Update the <code>flagging_donor2</code> module's <code>addFlag</code> function to not have a return value anymore
11. Compile <code>crowdfunding</code> module => Error: Expected single type, but found list type

How a module can be updated while it has already been published is limited. A module can be updated thanks to the upgrade policy declared in the <code>Move.toml</code> file being <code>compatible</code>. According to Aptos's website, this upgrade policy has the following restrictions [7](https://aptos.dev/guides/move-guides/upgrading-move-code/):
- For storage, all old struct declarations must be the same in the new code. However, new struct declarations can be added. This ensures that the new code correctly interprets the existing storage state.
- All existing public functions must have the same signature as before for APIs. New functions, including public and entry functions, can be added.

### Experiment 5: Transfer more than one owns
This experiment was conducted to see what kind of built-in error is thrown when someone tries to donate more than what is in their account. For this experiment to work, the balance check was removed from the <code>crowdfunding</code> module's <code>donate</code> function. 

1. Publish both the <code>crowdfunding</code> module and the <code>flagging_donor</code> module after removing the balance check in <code>crowdfunding</code> module's <code>donate</code> function 
2. Initialise crowdfunding
3. Donate more than the balance of the current account => EINSUFFICIENT_BALANCE error is thrown before the transaction is executed

This proves that an Aptos Move built-in check checks your balance before transferring a certain amount. This check is executed before the transaction is sent. Thus it prevents paying transaction fees for a transaction that would revert. For this experiment, we must note that we executed it with the native Aptos token APT. Thus, the built-in check may be only executed when using APT rather than when one uses custom resources.

### Experiment 6: Unchecked external call
The goal is to see if errors thrown during an unchecked external call are still caught and prevent the transaction from ever happening. For this experiment, a test version of the <code>addFlag</code> function was added to the <code>flagging_donor</code> module, and a test version of the <code>donate</code> function was added to the <code>crowdfunding</code> module. When the test is run, it should succeed, which means that the error is thrown in the <code>flagging_donor</code> module was pushed upwards to the <code>crowdfunding</code> module.

To run this experiment, perform the following command in the [WI_Crowdfunding](../WI_Crowdfunding/) directory: <code>aptos move test</code>.


## Conclusion


## Sources
1. [Pontem Network Docs](https://docs.pontem.network/02.-move-language/lang)
2. [Diem Move Docs](https://diem.github.io/move/introduction.html)
3. [Move Fast & Break Things Part 1: Move Security (Aptos)](https://www.zellic.io/blog/move-fast-and-break-things-pt-1)
4. [Move language Tutorial](https://github.com/move-language/move/tree/main/language/documentation/tutorial)
5. [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)
6. [Aptos Module/ Resource Explorer](https://aptos-module-explorer.vercel.app/)
7. [Aptos Move - Upgrade Move code](https://aptos.dev/guides/move-guides/upgrading-move-code/)


