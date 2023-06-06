# How to start a Move project

# How to start a Move project

1. **********************************************************************************************Start by creating a directory and initialise it**********************************************************************************************
    
    ```bash
    mkdir projectName
    cd projectName
    aptos move init --name ProjectName
    ```
    
2. ************************************************************************************************************************Add the necessary dependencies and addresses in the************************************************************************************************************************ `Move.tml` ********file********
    
    ```jsx
    [package]
    name = 'ProjectName'
    version = '1.0.0'
    upgrade_policy = 'compatible'
    
    [dependencies.AptosFramework]
    git = 'https://github.com/aptos-labs/aptos-core.git'
    rev = 'devnet'
    subdir = 'aptos-move/framework/aptos-framework'
    
    [addresses]
    std = "0x01"
    testing = "_"
    ```
    
3. ****************************************Add file in**************************************** `sources` ********directory********
    
    ```bash
    cd projectName
    cd sources
    touch projectname.move
    ```
    

# How to compile and test Move projects

1. ********************************************************Create a******************************************************** `tests` ********************************************************directory and add a test file that contains the tests you want to perform********************************************************
    
    ```bash
    cd projectName
    mkdir tests
    cd tests
    touch projectNameTests.move
    ```
    
    ```jsx
    #[test_only]
    module testing::projectNameTests{
        use testing::projectName;
    
        #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
        #[expected_failure(abort_code = flagging_donor::EDONOR_FLAGGED)]
        fun test_pass_signer(fund: signer, donor_a: signer, donor_b: signer, framework: signer) 
    		{
            ...
    		}
    }
    ```
    
2. ********************************Compile and test project********************************
    
    ```jsx
    aptos init
    aptos move compile --named-addresses testing=default
    aptos move test --named-addresses testing=default
    ```
    
    `named-addresses` must be specified because we didn't attribute a value to the `testing` variable in `Move.toml`. If a value is attributed, no named value must be specified. The `default` value specified refers to the account value created using `aptos init`. This value can be found in the `.aptos/config.yaml` file.
    

# How to deploy and run a project

1. **************************In************************** `Move.toml` **************************set the address at which your module will be deployed equal to the account address mentioned in the************************** `.aptos/config.yaml` **************************file**************************
    
    `config.yaml` file:
    
    ```jsx
    ---
    profiles:
      default:
        private_key: "0x2e3e5776889eaeff37524da5f704312e9f66b69a03efd2cb419ebd7f98db4c98"
        public_key: "0xde348ebdc5a5cb26004024069da577b1f3b3be895be858cb426356798b5ee235"
        account: d5626a5be6ddbd7299a6a8f335f5ec90402443939287159fd443244fffbbc725
        rest_url: "https://fullnode.devnet.aptoslabs.com"
        faucet_url: "https://faucet.devnet.aptoslabs.com"
    ```
    
    `Move.toml` file:
    
    ```jsx
    [package]
    name = 'CrowdfundingContract'
    version = '1.0.0'
    
    [dependencies.AptosFramework]
    git = 'https://github.com/aptos-labs/aptos-core.git'
    rev = 'devnet'
    subdir = 'aptos-move/framework/aptos-framework'
    
    [addresses]
    std = "0x1"
    testing = "0xd5626a5be6ddbd7299a6a8f335f5ec90402443939287159fd443244fffbbc725"
    ```
    
2. ****************************************************************Compile and deploy your project****************************************************************
    
    ```jsx
    aptos move compile
    aptos move publish
    ```
    
3. **********************************Run a transaction**********************************
    
    ```jsx
    FUNDADDRESS=0xd5626a5be6ddbd7299a6a8f335f5ec90402443939287159fd443244fffbbc725
    aptos move run --function-id $FUNDADDRESS::crowdfunding_contract::initialize_crowdfunding --args u64:"30000000" u64:"10" --type-args 0x1::aptos_coin::AptosCoin
    ```
    
    Here we first define a global variable in the terminal that will be saved for the whole terminal session. This allows us to not always type the whole address for every transaction. We then run the `initialize_crowdfunding` function with the required arguments.
    

# Sources

- [https://docs.pontem.network/03.-tutorials/aptos-tutorial](https://docs.pontem.network/03.-tutorials/aptos-tutorial)
- [https://aptos.dev/guides/move-guides/guide-move-transactional-testing/#run-module-script-functions](https://aptos.dev/guides/move-guides/guide-move-transactional-testing/#run-module-script-functions)
-