# Move overflow test case

## Goal 
The goal of this research is to compare Move to Solidity and see if Move is able to solve the most common vulnerabilities found in Solidity. The most common Solidity bugs are therefore replicated using the Move programming language and the Aptos Move framework to see if they are still prevelent or, if they are catched durimg compilation or at runtime.

This particular experiment is created to prove that the Move VM is able to detect over/underflows and thus prevent bugs related to them.

## How to run the experiment?
1. Download the Aptos Move CLI like explained at [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)
2. Download the *Overflow_Tests* directory
3. <code>cd</code> into the directory
4. Run the following commands:
    <code>
        aptos init
        aptos move compile --named-addresses testing=default
        aptos move test --named-addresses testing=default
    </code>

## Findings
When the tests are run, one can see that there are three tests being run with the following outcomes:
- The first test in which an unsignes integer of 8 bits equal to 255 is overflown by adding 1 to it, throws an error.
- The second test overflows the same unsigned int but this time it uses a bitshift left instead of an addition. This test passes without a problem.
- The third test underflows the 8 bit unsigned int 0 by substracting 1. This is caught by the Move VM.

## Discussion
We can see that the Move VM can detect overflows and underflows at runtime and throws an error when they happen. But it can only detect overflows when using arithmetic operations. Once, more exotic techniques like bitshifts are used, the VM fails to detect and flag the overflow. Luckily, the more exotic operations are not as common, which means that in most cases and thus contracts the Move VM will be able to detect overflows. This makes the Move language safer than older versions of Solidity (version prior to Solidity 0.8) which did not natively detect overflows at all. Solidity version 0.8 and newer do have an inherit overflow detection which make it on par with Move. 

## Conclusion
The Move VM can detect overflows and underflows caused by arithmetic operations, and it throws an error when they happen.

## Sources
1. [Pontem Network Docs](https://docs.pontem.network/02.-move-language/lang)
2. [Diem Move Docs](https://diem.github.io/move/introduction.html)
3. [Move Fast & Break Things Part 1: Move Security (Aptos)](https://www.zellic.io/blog/move-fast-and-break-things-pt-1)
4. [Move language Tutorial](https://github.com/move-language/move/tree/main/language/documentation/tutorial)
5. [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)