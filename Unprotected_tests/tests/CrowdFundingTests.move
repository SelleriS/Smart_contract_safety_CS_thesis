#[test_only]
module testing::crowdfundingTests{
    use testing::crowdfunding;
    use aptos_framework::account;
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::timestamp;

    const ANYONE_CAN_CLAIM_DONATIONS: u64 = 8;
    const ANYONE_CAN_INITIALIZE: u64 = 9;

    #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
    #[expected_failure(abort_code = ANYONE_CAN_CLAIM_DONATIONS)]
    fun test_only_owner_can_claim(fund: signer, donor_a: signer, donor_b: signer, framework: signer) {
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        let goal = 300u64;
        let numberOfMinutes = 1u64;
        let totalMoney = 1000u64;
        
        account::create_account_for_test(signer::address_of(&fund));
        account::create_account_for_test(signer::address_of(&donor_a));
        account::create_account_for_test(signer::address_of(&donor_b));
        account::create_account_for_test(signer::address_of(&framework));
        
        crowdfunding::initialize_crowdfunding<coin::FakeMoney>(&fund, goal, numberOfMinutes);
        coin::create_fake_money(&framework, &donor_a, totalMoney);
        coin::register<coin::FakeMoney>(&donor_b);
        coin::register<coin::FakeMoney>(&fund);
        coin::transfer<coin::FakeMoney>(&framework, signer::address_of(&donor_a), 500);
        coin::transfer<coin::FakeMoney>(&framework, signer::address_of(&donor_b), 500);

        crowdfunding::donate<coin::FakeMoney>(&donor_a, 200);
        crowdfunding::donate<coin::FakeMoney>(&donor_b, 200);

        crowdfunding::claimFunds<coin::FakeMoney>(&donor_a);

        let balance_a = coin::balance<coin::FakeMoney>(signer::address_of(&donor_a));
        assert!(balance_a <= 200, ANYONE_CAN_CLAIM_DONATIONS); // <===== Error is thrown because donor_a's balance is above 200 which means donor_a has claimed the funds of the contract
    }
}