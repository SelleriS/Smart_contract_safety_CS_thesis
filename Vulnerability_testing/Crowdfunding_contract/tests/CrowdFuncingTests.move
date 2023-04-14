#[test_only]
module testing::crowdfundingTests{
    use testing::crowdfunding;
    use aptos_framework::account;
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::timestamp;

    #[test(fund = @testing,  donor_a = @0xAA, framework = @aptos_framework)]
    #[expected_failure(abort_code = crowdfunding::EONLY_DEPLOYER_CAN_INITIALIZE)]
    fun test_only_deployer_can_initialize(fund: signer, donor_a: signer, framework: signer) {
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        let goal = 300u64;
        let numberOfMinutes = 1u64;
        
        account::create_account_for_test(signer::address_of(&fund));
        account::create_account_for_test(signer::address_of(&donor_a));
        account::create_account_for_test(signer::address_of(&framework));
        
        crowdfunding::initialize_crowdfunding<coin::FakeMoney>(&donor_a, goal, numberOfMinutes);
    }

    #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
    #[expected_failure(abort_code = crowdfunding::ENO_SUFFICIENT_FUND)]
    fun test_not_enough_funds(fund: signer, donor_a: signer, donor_b: signer, framework: signer) {
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
        coin::transfer<coin::FakeMoney>(&framework, signer::address_of(&donor_a), 100);
        coin::transfer<coin::FakeMoney>(&framework, signer::address_of(&donor_b), 500);

        crowdfunding::donate<coin::FakeMoney>(&donor_a, signer::address_of(&fund), 200);
        crowdfunding::donate<coin::FakeMoney>(&donor_b, signer::address_of(&fund), 100);
    }


    #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
    #[expected_failure(abort_code = crowdfunding::ENO_DEPOSIT)]
    fun test_no_deposit(fund: signer, donor_a: signer, donor_b: signer, framework: signer) {
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

        crowdfunding::donate<coin::FakeMoney>(&donor_a, signer::address_of(&fund), 200);
        crowdfunding::getRefund_test<coin::FakeMoney>(&donor_b, signer::address_of(&fund));
    }


    #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
    #[expected_failure(abort_code = crowdfunding::ECAMPAIGN_NOT_YET_EXPIRED)]
    fun test_refund_not_yet_expired(fund: signer, donor_a: signer, donor_b: signer, framework: signer) {
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

        crowdfunding::donate<coin::FakeMoney>(&donor_a, signer::address_of(&fund), 200);
        crowdfunding::getRefund<coin::FakeMoney>(&donor_a, signer::address_of(&fund));
    }

    #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
    #[expected_failure(abort_code = crowdfunding::ECAMPAIGN_GOAL_NOT_REACHED)]
    fun test_goal_not_reached(fund: signer, donor_a: signer, donor_b: signer, framework: signer) {
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

        crowdfunding::donate<coin::FakeMoney>(&donor_a, signer::address_of(&fund), 100);
        crowdfunding::donate<coin::FakeMoney>(&donor_b, signer::address_of(&fund), 100);

        crowdfunding::claimFunds_test<coin::FakeMoney>(&fund, signer::address_of(&fund));
    }

    #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
    #[expected_failure(abort_code = crowdfunding::ECAMPAIGN_GOAL_REACHED)]
    fun test_refund_goal_not_reached(fund: signer, donor_a: signer, donor_b: signer, framework: signer) {
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

        crowdfunding::donate<coin::FakeMoney>(&donor_a, signer::address_of(&fund), 400);
        crowdfunding::getRefund<coin::FakeMoney>(&donor_a, signer::address_of(&fund));
    }

    #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
    #[expected_failure(abort_code = crowdfunding::EONLY_CROWDFUNDING_OWNER_CAN_PERFORM_THIS_OPERATION)]
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

        crowdfunding::donate<coin::FakeMoney>(&donor_a, signer::address_of(&fund), 200);
        crowdfunding::donate<coin::FakeMoney>(&donor_b, signer::address_of(&fund), 100);

        crowdfunding::claimFunds_test<coin::FakeMoney>(&donor_a, signer::address_of(&fund));
    }

    #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
    #[expected_failure(abort_code = crowdfunding::ECAMPAIGN_DOES_NOT_EXIST)]
    fun test_no_cf_init(fund: signer, donor_a: signer, donor_b: signer, framework: signer) {
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        //let goal = 300u64;
        //let numberOfMinutes = 1u64;
        let totalMoney = 1000u64;
        
        account::create_account_for_test(signer::address_of(&fund));
        account::create_account_for_test(signer::address_of(&donor_a));
        account::create_account_for_test(signer::address_of(&donor_b));
        account::create_account_for_test(signer::address_of(&framework));
        
        //crowdfunding::initialize_crowdfunding<coin::FakeMoney>(&fund, goal, numberOfMinutes);
        coin::create_fake_money(&framework, &donor_a, totalMoney);
        coin::register<coin::FakeMoney>(&donor_b);
        coin::register<coin::FakeMoney>(&fund);
        coin::transfer<coin::FakeMoney>(&framework, signer::address_of(&donor_a), 500);

        crowdfunding::donate<coin::FakeMoney>(&donor_a, signer::address_of(&fund), 200);
    }

    #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
    fun test_success(fund: signer, donor_a: signer, donor_b: signer, framework: signer) {
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

        crowdfunding::donate<coin::FakeMoney>(&donor_a, signer::address_of(&fund), 200);
        crowdfunding::donate<coin::FakeMoney>(&donor_b, signer::address_of(&fund), 200);

        crowdfunding::claimFunds_test<coin::FakeMoney>(&fund, signer::address_of(&fund));
    }
}