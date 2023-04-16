#[test_only]
module testing::dao_tests{
    use testing::amm_contract;
    use aptos_framework::account;
    use std::signer;
    use aptos_framework::coin::{Self, FakeMoney};

    #[test(owner = @testing, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_initialise(owner: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&framework));

        let totalFakeMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalFakeMoney);
        coin::register<FakeMoney>(&owner);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        
        amm_contract::initialise_amm<FakeMoney,FakeMoney>(&owner);
        assert!(amm_contract::is_owner_test<FakeMoney,FakeMoney>(&owner), 101);
    }

    #[test(owner = @testing,  new_owner = @0xAA, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_ownership_transfer(owner: signer, new_owner: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&new_owner));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&new_owner);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&new_owner), 50000000);
        
        amm_contract::initialise_amm<FakeMoney,FakeMoney>(&owner);

        //Transfer AMM to new owner
        amm_contract::initiate_ownership_transfer<FakeMoney,FakeMoney>(&owner, signer::address_of(&new_owner));
        amm_contract::transfer_ownership<FakeMoney,FakeMoney>(&new_owner, signer::address_of(&owner));
        assert!(amm_contract::is_owner_test<FakeMoney,FakeMoney>(&new_owner), 101);
    }

    #[test(owner = @testing,  user = @0xAA, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_swap(owner: signer, user: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&user));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&user);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&user), 50000000);
        
        amm_contract::initialise_amm<FakeMoney,FakeMoney>(&owner);

        //Transfer AMM to new owner
        amm_contract::swap<FakeMoney,FakeMoney,FakeMoney>(&user, signer::address_of(&owner), 10000000);
    }

    #[test(owner = @testing,  user = @0xAA, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_add_liquidity(owner: signer, user: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&user));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&user);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&user), 50000000);
        
        amm_contract::initialise_amm<FakeMoney,FakeMoney>(&owner);

        //Transfer AMM to new owner
        amm_contract::add_liquidity<FakeMoney,FakeMoney>(&user, signer::address_of(&owner), 10000000, 10000000);
        assert!(amm_contract::is_share_owner_test<FakeMoney,FakeMoney>(&user), 101);
    }

    #[test(owner = @testing,  user = @0xAA, framework = @aptos_framework)]
    #[expected_failure]
    fun test_remove_liquidity(owner: signer, user: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&user));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&user);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&user), 50000000);
        
        amm_contract::initialise_amm<FakeMoney,FakeMoney>(&owner);

        //Transfer AMM to new owner
        amm_contract::add_liquidity<FakeMoney,FakeMoney>(&user, signer::address_of(&owner), 10000000, 10000000);
        let n_shares = amm_contract::how_many_shares_test<FakeMoney,FakeMoney>(&user);
        amm_contract::remove_liquidity<FakeMoney,FakeMoney>(&user, signer::address_of(&owner), n_shares);
        assert!(amm_contract::is_share_owner_test<FakeMoney,FakeMoney>(&user), 101);
    }




}