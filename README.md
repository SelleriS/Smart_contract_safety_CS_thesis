# Smart contract safety: A comparative study between Solidity and Move smart contract languages

This repository contains all the code experiments conducted for my master's thesis to obtain my degree in Engineering Science: Computer science at the KU Leuven. These experiments were conducted in two main programming languages, namely Solidity and Move. 

## Abstract

Blockchain technology has profoundly impacted numerous industries since its in- troduction in 2008. It is used in fields like supply chain management, identity management, governance, etc. Its widespread use is primarily due to its support for smart contracts, which are immutable self-operating computer programs that passively automate the execution of an agreement when certain conditions are met. Smart contracts have numerous use cases, including the management of million-dollar funds. This makes them prime targets for malicious actors. Million-dollar heists such as The DAO hack show the importance of securing smart contracts.

The most effective way of minimising vulnerabilities in smart contracts is by deeply understanding the employed programming language allowing for an idiomatic use. Nevertheless, some languages, like Move, are better equipped to minimise vulnerabilities due to their security-focused design philosophy. Move was developed in 2019 for the Diem project and is currently used by the Aptos and Sui projects. It is a resource-oriented language with special safety features. These features have, however, never been compared with other languages. Therefore, this thesis aims to compare Move’s relative safety and expressivity with the popular and widely adopted language, Solidity. Solidity is best known for its expressivity and has been extensively researched by the scientific community resulting in the discovery of numerous vulnerabilities.

A safety comparison is achieved by porting the most common Solidity vulnerabilities into Move and observing their effects. Results show that Move could mitigate 72% of most common Solidity vulnerabilities, highlighting the efficacy of its safety features. However, due to a lack of research about Move vulnerabilities, it cannot be concluded that Move is a safer language than Solidity. Move can still have substantial vulnerabilities that have yet to be discovered and which are not prevalent in Solidity.

An expressivity comparison is achieved by examining how Solidity contracts can be translated to Move and studying whether the translation process can be automated. Despite the differences in their programming paradigms, the translation did not pose any problems. This suggests that Move is expressive enough to capture common Solidity code patterns even though it is less expressive than Solidity.

This thesis is one of the first to study Move’s safety and expressivity compared to Solidity. In conclusion, the study revealed that Move’s safety features prevent common Solidity vulnerabilities while preserving its ability to capture common Solidity code patterns. However, additional research is needed, given the lack of known Move vulnerabilities.