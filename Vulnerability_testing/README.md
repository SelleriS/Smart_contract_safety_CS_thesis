# Aptos Move vulnerability test cases

## Goal 
This research aims to compare Move to Solidity and see if Move can solve the most common vulnerabilities found in Solidity. The most common Solidity bugs are replicated using the Move programming language and the Aptos Move framework to see if they are still prevalent or caught during compilation or runtime.

## Vulnerabilities
To prevent bias and cherry-picking vulnerabilities, it has been chosen to investigate a vulnerability list that was already created by a third party. For this research, the [The Awesome Buggy ERC20 tokens](https://github.com/sec-bit/awesome-buggy-erc20-tokens) was chosen as a starting point.

Each of the vulnerabilities of this list was researched which unveiled more general categories of vulnerabilities. Before starting the experiments, all vulnerabilities were first grouped together in their respective categories and were labeled. The different labels are:
- Overflow/Underflow
- Logic error
- Constructor naming
- Access control
- Wrong interface

Usually, it was enough to conduct one experiment per category to see if the Solidity vulnerability of that category is still present in the Move smart contract programming language. 

Because certain important vulnerabilities (eg. re-entrancy) were not included in the researched vulnerability list. Another list of vulnerabilities was also looked at, namely [Not so smart contracts](https://github.com/crytic/not-so-smart-contracts). This list not only includes Solidity vulnerabilities related to tokens, but also vulnerabilities related to the blockchain. For that reason an extra label is added to the list, namely *Blockchain*.


## Sources
1. [Pontem Network Docs](https://docs.pontem.network/02.-move-language/lang)
2. [Diem Move Docs](https://diem.github.io/move/introduction.html)
3. [Move Fast & Break Things Part 1: Move Security (Aptos)](https://www.zellic.io/blog/move-fast-and-break-things-pt-1)
4. [Move language Tutorial](https://github.com/move-language/move/tree/main/language/documentation/tutorial)
5. [Aptos Move CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)
6. [Aptos Module/ Resource Explorer](https://aptos-module-explorer.vercel.app/)
