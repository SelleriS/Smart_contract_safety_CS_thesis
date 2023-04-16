module testing::amm_contract{
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::coin::{Self, Coin};

//ERROR CODES
    const EONLY_DEPLOYER_CAN_INITIALIZE: u64 = 0; 
    const ENO_AMM_AT_ADDRESS: u64 = 1;
    const EONLY_OWNER_CAN_CALL: u64 = 2;
    const ETRANSFER_NOT_APPROVED_BY_OWNER: u64 = 3;
    const ENO_SUFFICIENT_FUND: u64 = 4;
    const EAMOUNT_IS_ZERO: u64 = 5;
    const EAMOUNTS_NOT_IN_BALANCE: u64 = 6;
    const ENO_SHARES_AT_ADDRESS: u64 = 7;
    const ENOT_ENOUGH_SHARES: u64 = 8;

//CONSTANTS
    const FEE_PERMILLE: u64 = 3; //Fee of 0.3%

    struct AMM<phantom CoinType1, phantom CoinType2> has key {
        new_owner: address,
        coin1: Coin<CoinType1>,
        coin2: Coin<CoinType2>,
        total_n_shares: u64,
        swapped_event: EventHandle<SwappedEvent>,
        liquidity_added_event: EventHandle<LiquidityAddedEvent>,
        liquidity_removed_event: EventHandle<LiquidityRemovedEvent>,
    }

    struct Shares has key {
        number_of_shares: u64,
    }

    struct SwappedEvent has drop, store {
        amount_in: u64,
        amount_out: u64,
    }

    struct LiquidityAddedEvent has drop, store {
        amount_in1: u64,
        amount_in2: u64,
        shares_issued: u64,
    }

    struct LiquidityRemovedEvent has drop, store {
        shares_swapped: u64,
        amount_out1: u64,
        amount_out2: u64,
    }

//OWNERSHIP
    public entry fun initialise_amm<CoinType1, CoinType2>(owner: &signer) {
        let owner_address = signer::address_of(owner);
        assert!(owner_address == @testing, EONLY_DEPLOYER_CAN_INITIALIZE);

        let coin1_empty = coin::withdraw<CoinType1>(owner, 0);
        let coin2_empty = coin::withdraw<CoinType2>(owner, 0);
        move_to(
            owner,
            AMM<CoinType1, CoinType2> {
                new_owner: owner_address,
                coin1: coin1_empty,
                coin2: coin2_empty,
                total_n_shares: 0,
                swapped_event: account::new_event_handle<SwappedEvent>(owner),
                liquidity_added_event: account::new_event_handle<LiquidityAddedEvent>(owner),
                liquidity_removed_event: account::new_event_handle<LiquidityRemovedEvent>(owner),
            }
        );
    }

    public entry fun initiate_ownership_transfer<CoinType1, CoinType2>(owner: &signer, new_owner_address: address) acquires AMM{
        only_owner<CoinType1,CoinType2>(owner);
        let new_owner = &mut borrow_global_mut<AMM<CoinType1,CoinType2>>(signer::address_of(owner)).new_owner;
        *new_owner = new_owner_address;
    }

    public entry fun transfer_ownership<CoinType1, CoinType2>(new_owner: &signer, owner_address: address) acquires AMM{
        assert!(exists<AMM<CoinType1, CoinType2>>(owner_address), ENO_AMM_AT_ADDRESS);

        // Check if the new owner address in the supplychain resource is equal to the new_owner that is trying to transfer
        let amm = borrow_global<AMM<CoinType1, CoinType2>>(owner_address);
        assert!(amm.new_owner == signer::address_of(new_owner), ETRANSFER_NOT_APPROVED_BY_OWNER);
        
        move_to<AMM<CoinType1, CoinType2>>(new_owner, move_from<AMM<CoinType1,CoinType2>>(owner_address));
    }

//AMM FUNCTIONALITY
    //Use CoinType3 to indicate which CoinType you want to swap. It must be equal to either CoinType1 or CoinType2
    public entry fun swap<CoinType1, CoinType2, CoinType3>(user: &signer, amm_address: address, amount: u64) acquires AMM {
        let is_CoinType1 = only_if_amm<CoinType1, CoinType2, CoinType3>(amm_address);
        let coins_in = check_balance_and_withdraw<CoinType3>(user, amount);
        
        //Caluclating fee
        let fee_amount = (amount * FEE_PERMILLE)/ 1000;
        let coins_as_fee = coin::extract(&mut coins_in, fee_amount);

        //Swap
        let coins_in_amount = coin::value<CoinType3>(& coins_in);
        let coins_out_amount;
        if(is_CoinType1){
            let amm = borrow_global_mut<AMM<CoinType3, CoinType2>>(amm_address);
            let coins_in_reserve = coin::value<CoinType3>(& amm.coin1);
            let coins_out_reserve = coin::value<CoinType2>(& amm.coin2);
            coins_out_amount = (coins_out_reserve * coins_in_amount)/ (coins_in_reserve + coins_in_amount);
            let coins_out = coin::extract<CoinType2>(&mut amm.coin2, coins_out_amount);
            coin::merge<CoinType3>(&mut amm.coin1, coins_in);
            coin::merge<CoinType3>(&mut amm.coin1, coins_as_fee);
            coin::deposit<CoinType2>(signer::address_of(user), coins_out);

        } else {
            let amm = borrow_global_mut<AMM<CoinType1, CoinType3>>(amm_address);
            let coins_in_reserve = coin::value<CoinType3>(& amm.coin2);
            let coins_out_reserve = coin::value<CoinType1>(& amm.coin1);
            coins_out_amount = (coins_out_reserve * coins_in_amount)/ (coins_in_reserve + coins_in_amount);
            let coins_out = coin::extract<CoinType1>(&mut amm.coin1, coins_out_amount);
            coin::merge<CoinType3>(&mut amm.coin2, coins_in);
            coin::merge<CoinType3>(&mut amm.coin2, coins_as_fee);
            coin::deposit<CoinType1>(signer::address_of(user), coins_out);
        };

        let amm = borrow_global_mut<AMM<CoinType1, CoinType2>>(amm_address);
        event::emit_event<SwappedEvent>(
            &mut amm.swapped_event,
            SwappedEvent { 
                amount_in: coins_in_amount,
                amount_out: coins_out_amount,
            },
        );
    }

    public entry fun add_liquidity<CoinType1, CoinType2>(user: &signer, amm_address: address, amount1: u64, amount2: u64) acquires AMM, Shares {
        assert!(exists<AMM<CoinType1, CoinType2>>(amm_address), ENO_AMM_AT_ADDRESS);
        let user_address = signer::address_of(user);
        let coins1_in = check_balance_and_withdraw<CoinType1>(user, amount1);
        let coins2_in = check_balance_and_withdraw<CoinType2>(user, amount2);
        let amm = borrow_global_mut<AMM<CoinType1, CoinType2>>(amm_address);
        let coins1_reserve = coin::value<CoinType1>(& amm.coin1);
        let coins2_reserve = coin::value<CoinType2>(& amm.coin2);

        //This should be changed to calulate how much amount2 must be based on amount1 and the current state of the AMM
        if(coins1_reserve > 0 || coins2_reserve > 0) {
            assert!(coins1_reserve * amount2 == coins2_reserve * amount1, EAMOUNTS_NOT_IN_BALANCE);
        };

        //Calculate number of shares to issue
        let number_of_shares;
        if(amm.total_n_shares == 0){
            number_of_shares = sqrt(amount1 * amount2);
        } else {
            let number1 = (amount1 * amm.total_n_shares) / coins1_reserve;
            let number2 = (amount2 * amm.total_n_shares) / coins2_reserve;
            number_of_shares = minimum(number1, number2);
        };

        //Deposit the coins to th eAMM
        coin::merge<CoinType1>(&mut amm.coin1, coins1_in);
        coin::merge<CoinType2>(&mut amm.coin2, coins2_in);

        //Issue the shares
        if(!exists<Shares>(user_address)){
            move_to(user, Shares{number_of_shares: number_of_shares});
        } else{
            let current_number_of_shares = &mut borrow_global_mut<Shares>(user_address).number_of_shares;
            *current_number_of_shares = *current_number_of_shares + number_of_shares;
        };
        amm.total_n_shares = amm.total_n_shares + number_of_shares;

        event::emit_event<LiquidityAddedEvent>(
            &mut amm.liquidity_added_event,
            LiquidityAddedEvent { 
                amount_in1: amount1,
                amount_in2: amount2,
                shares_issued: number_of_shares,
            },
        );
    }

    public entry fun remove_liquidity<CoinType1, CoinType2>(user: &signer, amm_address: address, number_of_shares: u64) acquires AMM, Shares {
        let user_address = signer::address_of(user);
        assert!(exists<Shares>(user_address), ENO_SHARES_AT_ADDRESS);
        assert!(exists<AMM<CoinType1, CoinType2>>(amm_address), ENO_AMM_AT_ADDRESS);
        let amm = borrow_global_mut<AMM<CoinType1, CoinType2>>(amm_address);
        let coins1_reserve = coin::value<CoinType1>(& amm.coin1);
        let coins2_reserve = coin::value<CoinType2>(& amm.coin2);

        burn_shares(user_address, number_of_shares);

        let amount1 = (number_of_shares * coins1_reserve)/ amm.total_n_shares;
        let amount2 = (number_of_shares * coins2_reserve)/ amm.total_n_shares;

        coin::deposit<CoinType1>(user_address, coin::extract<CoinType1>(&mut amm.coin1, amount1));
        coin::deposit<CoinType2>(user_address, coin::extract<CoinType2>(&mut amm.coin2, amount2));

        event::emit_event<LiquidityRemovedEvent>(
            &mut amm.liquidity_removed_event,
            LiquidityRemovedEvent { 
                shares_swapped: number_of_shares,
                amount_out1: amount1,
                amount_out2: amount2,
            },
        );
    }


//HELPER FUNCTIONS
    fun only_owner<CoinType1, CoinType2>(owner: &signer) {
        assert!(exists<AMM<CoinType1, CoinType2>>(signer::address_of(owner)), EONLY_OWNER_CAN_CALL);
    }

    //Checks if CoinType3 is either equal to CoinType1 or CoinType2 and returns if it + checks that an amm exists with CoinType1 and CoinType2
    fun only_if_amm<CoinType1, CoinType2, CoinType3>(amm_address: address): bool {
        let cond1 = exists<AMM<CoinType3, CoinType2>>(amm_address);
        let cond2 = exists<AMM<CoinType1, CoinType3>>(amm_address);
        assert!(cond1 || cond2, ENO_AMM_AT_ADDRESS);
        cond1
    }

    fun check_balance_and_withdraw<CoinType>(user: &signer, amount: u64): Coin<CoinType> {
        assert!(amount > 0, EAMOUNT_IS_ZERO);
        assert!(coin::balance<CoinType>(signer::address_of(user)) >= amount, ENO_SUFFICIENT_FUND);
        coin::withdraw<CoinType>(user, amount)
    }

    fun burn_shares(user_address: address, number_of_shares: u64) acquires Shares {
        let shares = borrow_global_mut<Shares>(user_address);
        let current_number_of_shares = &mut shares.number_of_shares;
        assert!(*current_number_of_shares >= number_of_shares, ENOT_ENOUGH_SHARES);
        *current_number_of_shares = *current_number_of_shares - number_of_shares;
        if(*current_number_of_shares == 0){
            let Shares{number_of_shares: _ } = move_from<Shares>(user_address);
        }
    }

    fun minimum (number1: u64, number2: u64): u64 {
        let result = number1;
        if(number2 < number1) {
            result = number2;
        };
        result
    }

    //Function taken from: https://solidity-by-example.org/defi/constant-product-amm/
    fun sqrt(number: u64): u64 {
        let result = 0;
        if (number > 3) {
            result = number;
            let x = number / 2 + 1;
            while (x < result) {
                result = x;
                x = (number / x + x) / 2;
            };
        } else if (number != 0) {
            result = 1;
        };
        result
    }


//TEST HELPER FUNCTIONS
    #[test_only]
    public entry fun is_owner_test<CoinType1, CoinType2>(owner: &signer): bool {
        exists<AMM<CoinType1, CoinType2>>(signer::address_of(owner))
    }

    #[test_only]
    public entry fun is_share_owner_test<CoinType1, CoinType2>(user: &signer): bool {
        exists<Shares>(signer::address_of(user))
    }

    #[test_only]
    public entry fun how_many_shares_test<CoinType1, CoinType2>(user: &signer): u64 acquires Shares {
        assert!(exists<Shares>(signer::address_of(user)),ENO_SHARES_AT_ADDRESS);
        borrow_global_mut<Shares>(signer::address_of(user)).number_of_shares
    }
}
