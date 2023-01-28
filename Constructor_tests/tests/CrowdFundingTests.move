#[test_only]
module testing::crowdfundingTests{
    use testing::crowdfunding;
    use aptos_framework::account;
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::timestamp;

    const ANYONE_CAN_INITIALIZE: u64 = 9;

    #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
    #[expected_failure(abort_code = ANYONE_CAN_INITIALIZE)]
    fun test_anyone_can_initialize(fund: signer, donor_a: signer, donor_b: signer, framework: signer) {
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        let goal = 300u64;
        let numberOfMinutes = 1u64;
        let totalMoney = 1000u64;
        
        // Creating accounts
        account::create_account_for_test(signer::address_of(&fund));
        account::create_account_for_test(signer::address_of(&donor_a));
        account::create_account_for_test(signer::address_of(&donor_b));
        account::create_account_for_test(signer::address_of(&framework));
        
        // Creating FakeMoney coins and registering them in the accounts that have to be able to handle (contain) them
        coin::create_fake_money(&framework, &donor_a, totalMoney);
        coin::register<coin::FakeMoney>(&donor_b);
        coin::register<coin::FakeMoney>(&fund);

        // Allocating the FaekMoeny coins to each donor account
        coin::transfer<coin::FakeMoney>(&framework, signer::address_of(&donor_a), 500);
        coin::transfer<coin::FakeMoney>(&framework, signer::address_of(&donor_b), 500);

        // Initialising the crowdfunding contract and donating FakeMoeny coins to it
        crowdfunding::initialize_crowdfunding<coin::FakeMoney>(&fund, goal, numberOfMinutes);       
        crowdfunding::donate<coin::FakeMoney>(&donor_a, signer::address_of(&donor_a), 200);
        crowdfunding::donate<coin::FakeMoney>(&donor_b, signer::address_of(&donor_a), 200);

        // Donor_a (= owner) claims teh funds 
        crowdfunding::claimFunds<coin::FakeMoney>(&donor_a, signer::address_of(&donor_a));

        let balance_a = coin::balance<coin::FakeMoney>(signer::address_of(&donor_a));
        assert!(balance_a <= 200, ANYONE_CAN_INITIALIZE); // <===== Error is thrown because donor_a's balance is above 200 which means donor_a has claimed the funds of the contract
    }

    // In this version donor_b doesn't know that the crowdfunding is at another address
    // Thus his transaction throws an error indicating that there is no crowdfunding at the address he wanted to donate to
    #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
    #[expected_failure(abort_code = testing::crowdfunding::CAMPAIGN_DOES_NOT_EXIST)]
    fun test_anyone_can_initialize2(fund: signer, donor_a: signer, donor_b: signer, framework: signer) {
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        let goal = 300u64;
        let numberOfMinutes = 1u64;
        let totalMoney = 1000u64;
        
        // Creating accounts
        account::create_account_for_test(signer::address_of(&fund));
        account::create_account_for_test(signer::address_of(&donor_a));
        account::create_account_for_test(signer::address_of(&donor_b));
        account::create_account_for_test(signer::address_of(&framework));
        
        // Creating FakeMoney coins and registering them in the accounts that have to be able to handle (contain) them
        coin::create_fake_money(&framework, &donor_a, totalMoney);
        coin::register<coin::FakeMoney>(&donor_b);
        coin::register<coin::FakeMoney>(&fund);

        // Allocating the FaekMoeny coins to each donor account
        coin::transfer<coin::FakeMoney>(&framework, signer::address_of(&donor_a), 500);
        coin::transfer<coin::FakeMoney>(&framework, signer::address_of(&donor_b), 500);

        // Initialising the crowdfunding contract and donating FakeMoeny coins to it
        crowdfunding::initialize_crowdfunding<coin::FakeMoney>(&fund, goal, numberOfMinutes);
        crowdfunding::donate<coin::FakeMoney>(&donor_a, signer::address_of(&donor_a), 200);
        crowdfunding::donate<coin::FakeMoney>(&donor_b, signer::address_of(&fund), 200); // <===== Error is thrown because the crowdfunding was hijacked by another account and so it is not at the same address
    }
}