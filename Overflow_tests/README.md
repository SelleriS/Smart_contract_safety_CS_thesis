# Move overflow test case

## Goal 
This research aims to compare Move to Solidity and see if Move can solve the most common vulnerabilities found in Solidity. The most common Solidity bugs are replicated using the Move programming language and the Aptos Move framework to see if they are still prevalent or caught during compilation or runtime.

This particular experiment is created to prove that the Move VM can detect over/underflows and thus prevent bugs related to them.

## How to run the experiment?
1. Download the [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)
2. Download the [Overflow Tests](../Overflow_tests/) directory
3. <code>cd</code> into the directory
4. Run the following commands:

    ```
        aptos init
        aptos move compile --named-addresses testing=default
        aptos move test --named-addresses testing=default
    ```

The Aptos CLI executable is saved in a *bin* folder in the home directory. An alias was created for the Aptos CLI to make the commands more readable. If the reader chooses not to create an alias, run the previous commands as follows: e.g. <code>~/bin/aptos init</code> instead of just using <code>aptos init</code>.

## Findings
When the tests are run, one can see that three tests are being run with the following outcomes:
- The first test, in which an unsigned integer of 8 bits equal to 255 is overflown by adding 1 to it, throws an error.
- The second test overflows the same unsigned int, but this time it uses a bitshift left instead of an addition. This test passes without a problem.
- The third test underflows the 8-bit unsigned int 0 by subtracting 1. The Move VM catches this.

## Discussion
We can see that the Move VM can detect overflows and underflows at runtime and throws an error when they happen. However, it can only detect overflows when using arithmetic operations. Once more exotic techniques like bitshifts are used, the VM fails to detect and flag the overflow. Luckily, the more exotic operations are not as common, which means that in most cases and thus contracts, the Move VM will be able to detect overflows. This makes the Move language safer than older versions of Solidity (version prior to Solidity 0.8), which did not natively detect overflows. Solidity version 0.8 and newer have an inherent overflow detection which makes it on par with Move. 

## Conclusion
The Move VM can detect overflows and underflows caused by arithmetic operations and throws an error when they happen.

## Sources
1. [Pontem Network Docs](https://docs.pontem.network/02.-move-language/lang)
2. [Diem Move Docs](https://diem.github.io/move/introduction.html)
3. [Move Fast & Break Things Part 1: Move Security (Aptos)](https://www.zellic.io/blog/move-fast-and-break-things-pt-1)
4. [Move language Tutorial](https://github.com/move-language/move/tree/main/language/documentation/tutorial)
5. [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)