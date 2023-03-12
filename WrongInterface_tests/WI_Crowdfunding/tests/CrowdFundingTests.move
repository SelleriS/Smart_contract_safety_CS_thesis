#[test_only]
module testing::crowdfundingTests{
    use testing::crowdfunding;
    use testing2::flagging_donor2 as flagging_donor;
    use aptos_framework::account;
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::timestamp;

    // Test to see if errors that occur in the Flagging contract are pushed upward to the crowdfunding contract
    // In this test the test_flagging function will throw an error if a donor tries to donate a second time
    #[test(fund = @testing,  donor_a = @0xAA, donor_b = @0xBB, framework = @aptos_framework)]
    #[expected_failure(abort_code = flagging_donor::EDONOR_FLAGGED)]
    fun test_pass_signer(fund: signer, donor_a: signer, donor_b: signer, framework: signer) {
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        let goal = 30000000u64;
        let numberOfMinutes = 1u64;
        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        
        // Creating accounts
        account::create_account_for_test(signer::address_of(&fund));
        account::create_account_for_test(signer::address_of(&donor_a));
        account::create_account_for_test(signer::address_of(&donor_b));
        account::create_account_for_test(signer::address_of(&framework));
        
        // Creating FakeMoney coins and registering them in the accounts that have to be able to handle (contain) them
        coin::create_fake_money(&framework, &donor_a, totalMoney);
        coin::register<coin::FakeMoney>(&donor_b);
        coin::register<coin::FakeMoney>(&fund);

        // Allocating the FakeMoney coins to each donor account
        coin::transfer<coin::FakeMoney>(&framework, signer::address_of(&donor_a), 50000000);
        coin::transfer<coin::FakeMoney>(&framework, signer::address_of(&donor_b), 50000000);

        // Initialising the crowdfunding contract and donating FakeMoney coins to it
        crowdfunding::initialize_crowdfunding<coin::FakeMoney>(&fund, goal, numberOfMinutes);
        crowdfunding::donate_test<coin::FakeMoney>(&donor_a, signer::address_of(&fund), 40000000);
        crowdfunding::donate_test<coin::FakeMoney>(&donor_b, signer::address_of(&fund), 20000000);
        crowdfunding::donate_test<coin::FakeMoney>(&donor_a, signer::address_of(&fund), 10000000); // should give an error
    }
}