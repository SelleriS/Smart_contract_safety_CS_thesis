#[test_only]
module testing2::callback_crowdfunding {
    use testing::crowdfunding as crowdfunding;

    public fun getRefund_callback<CoinType>(addr: address) {
        crowdfunding::getRefund<CoinType>(addr, @testing);
    }
}

#[test_only]
module testing::crowdfunding{
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, Coin};
    use testing2::callback_crowdfunding::getRefund_callback;


///////////////////////////////////////////////
//                Error Codes                //
///////////////////////////////////////////////
// Start Error constant names with an 'E'if you want the constant name to be displayed when the error is thrown
    const EONLY_DEPLOYER_CAN_INITIALIZE: u64 = 0; 

    const ENO_SUFFICIENT_FUND: u64 = 1;

    const ENO_DEPOSIT: u64 = 2;

    const ECAMPAIGN_NOT_YET_EXPIRED: u64 = 3;

    const ECAMPAIGN_EXPIRED: u64 = 4;

    const ECAMPAIGN_GOAL_NOT_REACHED: u64 = 5;

    const ECAMPAIGN_GOAL_REACHED: u64 = 6;

    const EONLY_CROWDFUNDING_OWNER_CAN_PERFORM_THIS_OPERATION: u64 = 7;

    const ECAMPAIGN_DOES_NOT_EXIST: u64 = 8;

    const ENOT_ALL_DONORS_ARE_REFUNDED: u64 = 9;

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
        n_of_donors: u64,
        funding: u64,
    }

///////////////////////////////////////////////
//                 Functions                 //
///////////////////////////////////////////////
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
                n_of_donors: 0,
                funding: 0,
            }
        );
    }

    public entry fun donate<CoinType>(account: &signer, fund_addr: address, amount: u64) acquires Deposit, CrowdFunding{
        assertCrowdfundingInitialized<CoinType>(fund_addr);
        assertDeadlinePassed<CoinType>(fund_addr, false);

        // Get address of `signer` by utilizing `Signer` module of Standard Library
        let addr = signer::address_of(account);
        assert!(coin::balance<CoinType>(addr) >= amount, ENO_SUFFICIENT_FUND);
        let coin_to_deposit = coin::withdraw<CoinType>(account, amount);
        let val = coin::value<CoinType>(&coin_to_deposit);
        let cf = borrow_global_mut<CrowdFunding<CoinType>>(fund_addr); 

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
            cf.n_of_donors = cf.n_of_donors + 1;
        } else{
            let deposit = borrow_global_mut<Deposit<CoinType>>(addr);
            coin::merge<CoinType>(&mut deposit.coin, coin_to_deposit);
        };
        // Add funding
        cf.funding = cf.funding + val;
    }


    public entry fun getRefund<CoinType>(account: &signer, fund_addr: address) acquires Deposit, CrowdFunding{
        assertCrowdfundingInitialized<CoinType>(fund_addr);
        assertGoalReached<CoinType>(fund_addr, false);
        assertDeadlinePassed<CoinType>(fund_addr, true);

        // Get address of `signer` by utilizing `Signer` module of Standard Library
        let addr = signer::address_of(account);
        assert!(exists<Deposit<CoinType>>(addr), ENO_DEPOSIT);

        // Extract `Deposit` resource from donor account.
        // And then deconstruct resource to get stored value.
        let Deposit<CoinType>{ coin: coins } = move_from<Deposit<CoinType>>(addr);
        coin::deposit(addr, coins);

        //External Call
        getRefund_callback<CoinType>(addr);

        // If all donors have asked for a refund, th CF object can be destroyed
        let n_of_donors = &mut borrow_global_mut<CrowdFunding<CoinType>>(fund_addr).n_of_donors;
        *n_of_donors = *n_of_donors - 1;
        if(*n_of_donors == 0){
            destroyCrowdfunding<CoinType>(fund_addr);
        };
    }

    // This function doesn't use Deposit, but it calls a function that does
    // So, this function has to acquire Deposit as well
    public entry fun claimFunds<CoinType>(account: &signer, fund_addr: address) acquires Deposit, CrowdFunding{
        assertCrowdfundingInitialized<CoinType>(fund_addr);
        assertGoalReached<CoinType>(fund_addr, true);
        assertDeadlinePassed<CoinType>(fund_addr, true);

        //CHECK: Only owner can call this function       
        let addr = signer::address_of(account);                               
        assert!(addr == fund_addr, EONLY_CROWDFUNDING_OWNER_CAN_PERFORM_THIS_OPERATION);

        let donors = &mut borrow_global_mut<CrowdFunding<CoinType>>(fund_addr).donors;
        withdrawCoinsFromDeposits<CoinType>(addr, donors);
        destroyCrowdfunding<CoinType>(fund_addr);
    }

    // Only callable if the deadline has passed, the goal hasn't been reached and there are no donors left to refund
    public entry fun selfDestruct<CoinType>(account: &signer, fund_addr: address) acquires CrowdFunding{
        assertCrowdfundingInitialized<CoinType>(fund_addr);
        assertDeadlinePassed<CoinType>(fund_addr, true);
        
        //CHECK: Only owner can call this function       
        let addr = signer::address_of(account);    
        assert!(addr == fund_addr, EONLY_CROWDFUNDING_OWNER_CAN_PERFORM_THIS_OPERATION);

        // This function can only be called if there are no donors
        let n_of_donors = borrow_global<CrowdFunding<CoinType>>(fund_addr).n_of_donors;
        assert!(n_of_donors == 0, ENOT_ALL_DONORS_ARE_REFUNDED);
        destroyCrowdfunding<CoinType>(fund_addr);
    }


///////////////////////////////////////////////
//             Helper Functions              //
///////////////////////////////////////////////
    // Check if the crowdfunding campaign is initialized/exists
    fun assertCrowdfundingInitialized<CoinType>(fund_addr: address) {
        assert!(exists<CrowdFunding<CoinType>>(fund_addr), ECAMPAIGN_DOES_NOT_EXIST);
    }

    // Check if deadline has passed
    fun assertDeadlinePassed<CoinType>(fund_addr: address, checkPassed: bool) acquires CrowdFunding{
        let cf = borrow_global<CrowdFunding<CoinType>>(fund_addr);
        let deadline = cf.deadline;
        //let now = timestamp::now_seconds()/DAY_CONVERSION_FACTOR;
        let now = timestamp::now_seconds()/MINUTE_CONVERSION_FACTOR;
        if(checkPassed){
            assert!(now >= deadline, ECAMPAIGN_NOT_YET_EXPIRED);
        } else {
            assert!(now < deadline, ECAMPAIGN_EXPIRED);
        }
        
    }

    // Check if goal is (not) reached
    fun assertGoalReached<CoinType>(fund_addr: address, checkReached: bool) acquires CrowdFunding{
        let cf = borrow_global<CrowdFunding<CoinType>>(fund_addr);
        if(checkReached){
            assert!(cf.funding >= cf.goal, ECAMPAIGN_GOAL_NOT_REACHED);
        } else {
            assert!(cf.funding < cf.goal, ECAMPAIGN_GOAL_REACHED);
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

    // Destroy crowdfunding resource by unpacking it into its fields. 
    // This is a privileged operation that can only be done inside the module that declares 
    // the `Crowdfunding` resource
    fun destroyCrowdfunding<CoinType>(fund_addr: address) acquires CrowdFunding{
        let CrowdFunding<CoinType>{
            goal: _goal,
            deadline: _deadline,
            donors: _donors,
            n_of_donors: _n_of_donors,
            funding: _funding,
        } = move_from<CrowdFunding<CoinType>>(fund_addr); 
    }
}