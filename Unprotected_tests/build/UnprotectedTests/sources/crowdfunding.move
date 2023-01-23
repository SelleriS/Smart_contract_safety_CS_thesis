module testing::crowdfunding{
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, Coin};

///////////////////////////////////////////////
//                Error Codes                //
///////////////////////////////////////////////
    const EONLY_DEPLOYER_CAN_INITIALIZE: u64 = 0;

    const ENO_SUFFICIENT_FUND: u64 = 1;

    const ENO_DEPOSIT: u64 = 2;

    const CAMPAIGN_NOT_YET_EXPIRED: u64 = 3;

    const CAMPAIGN_GOAL_NOT_REACHED: u64 = 4;

    const CAMPAIGN_GOAL_REACHED: u64 = 5;

    const EONLY_CROWDFUNDING_OWNER_CAN_PERFORM_THIS_OPERATION: u64 = 6;

    const CAMPAIGN_DOES_NOT_EXIST: u64 = 7;

    // Constants
    const DAY_CONVERSION_FACTOR: u64 = 24 * 60 * 60;

    const MINUTE_CONVERSION_FACTOR: u64 =  60;

///////////////////////////////////////////////
//                 Resources                 //
///////////////////////////////////////////////
    struct Deposit<phantom CoinType> has key {
        coin: Coin<CoinType>,
    }

    struct CrowdFunding<phantom CoinType> has key {
        goal: u64,
        deadline: u64,
        donors: vector<address>,
        funding: u64,
    }

///////////////////////////////////////////////
//                 Functions                 //
///////////////////////////////////////////////

    // This function serves as a constructor to initialize the contract
    public entry fun initialize_crowdfunding<CoinType>(account: &signer, goal: u64, numberOfMinutes: u64) {
        // CHECK: Only the account that deployed the contract can initialize it
        let addr = signer::address_of(account);
        assert!(addr == @testing, EONLY_DEPLOYER_CAN_INITIALIZE);          
        let now = timestamp::now_seconds()/MINUTE_CONVERSION_FACTOR;
        let deadline = now + numberOfMinutes;
        move_to(
            account,
            CrowdFunding<CoinType> {
                goal: goal,
                deadline: deadline,
                donors: vector::empty<address>(),
                funding: 0,
            }
        );
    }

    public entry fun donate<CoinType>(account: &signer, amount: u64) acquires Deposit, CrowdFunding{
        assertCrowdfundingInitialized<CoinType>();
        // Get address of `signer` by utilizing `Signer` module of Standard Library
        let addr = signer::address_of(account);
        assert!(coin::balance<CoinType>(addr) >= amount, ENO_SUFFICIENT_FUND);
        let coin_to_deposit = coin::withdraw<CoinType>(account, amount);
        let val = coin::value<CoinType>(&coin_to_deposit);
        let cf = borrow_global_mut<CrowdFunding<CoinType>>(@testing); 

        // Check if resource doesn't already exist. If it doesn't create one
        if(!exists<Deposit<CoinType>>(addr)){
            // Create `Deposit` resource containing provided amount of coins and cointype.
            let to_deposit = Deposit<CoinType> {coin: coin_to_deposit};
            // 'Move' the Deposit resource under user account,
            // so the resource will be placed into storage under user account.
            move_to(account, to_deposit);

            // Add donor to vector of donors
            let donors = &mut cf.donors;
            vector::push_back<address>(donors, addr);
        } else{
            let deposit = borrow_global_mut<Deposit<CoinType>>(addr);
            coin::merge<CoinType>(&mut deposit.coin, coin_to_deposit);
        };
        // Add funding
        cf.funding = cf.funding + val;
    }

    public entry fun getRefund<CoinType>(account: &signer) acquires Deposit, CrowdFunding{
        assertCrowdfundingInitialized<CoinType>();
        // Get address of `signer` by utilizing `Signer` module of Standard Library
        let addr = signer::address_of(account);
        
        // Checks 
        assert!(exists<Deposit<CoinType>>(addr), ENO_DEPOSIT);
        assertGoalReached<CoinType>(false);
        assertDeadlinePassed<CoinType>();

        // Extract `Deposit` resource from donor account.
        // And then deconstruct resource to get stored value.
        let Deposit<CoinType>{ coin: coins } = move_from<Deposit<CoinType>>(addr);
        coin::deposit(addr, coins);
    }

    /// This function doesn't use Deposit, but it calls a function that does
    /// So, this function has to acquire Deposit as well
    public entry fun claimFunds<CoinType>(account: &signer) acquires Deposit, CrowdFunding{
        assertCrowdfundingInitialized<CoinType>();
        assertGoalReached<CoinType>(true);
        let addr = signer::address_of(account);

        //CHECK: Only owner can call this function                                       <======= Removing this check makes the function unprotected!
        //assert!(addr == @testing, EONLY_CROWDFUNDING_OWNER_CAN_PERFORM_THIS_OPERATION);  

        let donors = &mut borrow_global_mut<CrowdFunding<CoinType>>(@testing).donors;
        withdrawCoinsFromDeposits<CoinType>(addr, donors);
    }

///////////////////////////////////////////////
//             Helper Functions              //
///////////////////////////////////////////////
    // Check if the crowd funding campaign is initialized/ exists
    fun assertCrowdfundingInitialized<CoinType>() {
        assert!(exists<CrowdFunding<CoinType>>(@testing), CAMPAIGN_DOES_NOT_EXIST);
    }

    // Check if deadline has passed
    fun assertDeadlinePassed<CoinType>() acquires CrowdFunding{
        let cf = borrow_global<CrowdFunding<CoinType>>(@testing);
        let deadline = cf.deadline;
        //let now = timestamp::now_seconds()/DAY_CONVERSION_FACTOR;
        let now = timestamp::now_seconds()/MINUTE_CONVERSION_FACTOR;
        assert!(now >= deadline, CAMPAIGN_NOT_YET_EXPIRED);
    }

    // Check if goal is (not) reached
    fun assertGoalReached<CoinType>(checkReached: bool) acquires CrowdFunding{
        let cf = borrow_global<CrowdFunding<CoinType>>(@testing);
        if(checkReached){
            assert!(cf.funding >= cf.goal, CAMPAIGN_GOAL_NOT_REACHED);
        } else {
            assert!(cf.funding < cf.goal, CAMPAIGN_GOAL_REACHED);
        };   
    }

    // Go through donors vector 
    // Withdraw their deposits and deposit the coins they contain at the crowdfunding address
    fun withdrawCoinsFromDeposits<CoinType>(fund_addr: address, donors: &mut vector<address>) acquires Deposit{
        while (!vector::is_empty<address>(donors)){
            let donor_addr = vector::pop_back<address>(donors);
            // Extract `Deposit` resource from donor account and deconstruct the resource to get stored coins
            let Deposit<CoinType>{ coin: coins } = move_from<Deposit<CoinType>>(donor_addr);
            coin::deposit(fund_addr, coins);
        }
    }
}