#[test_only]
module testing::dao_tests{
    use testing::dao_contract;
    use aptos_framework::account;
    use std::signer;
    use aptos_framework::coin::{Self, FakeMoney};
    use aptos_framework::timestamp;

    #[test(owner = @testing, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_initialise(owner: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        
        dao_contract::init_test_dao<FakeMoney>(&owner);
        assert!(dao_contract::is_owner_test<FakeMoney>(&owner), 101);
    }

    #[test(owner = @testing, framework = @aptos_framework)]
    #[expected_failure(abort_code = dao_contract::ENO_SUFFICIENT_FUND)]
    fun test_initialise_not_enough_funds(owner: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 9000000);
        
        dao_contract::init_test_dao<FakeMoney>(&owner);
        assert!(dao_contract::is_owner_test<FakeMoney>(&owner), 101);
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
        
        dao_contract::init_test_dao<FakeMoney>(&owner);
        assert!(dao_contract::is_owner_test<FakeMoney>(&owner), 101);

        //Transfer DAO to new owner
        dao_contract::apply_for_membership<FakeMoney>(&new_owner, signer::address_of(&owner));
        dao_contract::initiate_ownership_transfer<FakeMoney>(&owner, signer::address_of(&new_owner));
        dao_contract::transfer_ownership<FakeMoney>(&new_owner, signer::address_of(&owner));
        assert!(dao_contract::is_owner_test<FakeMoney>(&new_owner), 102);

        //Transfer DAO back to owner
        dao_contract::initiate_ownership_transfer<FakeMoney>(&new_owner, signer::address_of(&owner));
        dao_contract::transfer_ownership<FakeMoney>(&owner, signer::address_of(&new_owner));
        assert!(dao_contract::is_owner_test<FakeMoney>(&owner), 103);
    }

    #[test(owner = @testing,  member = @0xAA, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_apply_for_membership(owner: signer, member: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&member));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&member);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member), 50000000);

        dao_contract::init_test_dao<FakeMoney>(&owner);
        dao_contract::apply_for_membership<FakeMoney>(&member, signer::address_of(&owner));

        assert!(dao_contract::is_member_test<FakeMoney>(&member), 101);
    }

    #[test(owner = @testing,  member = @0xAA, framework = @aptos_framework)]
    //#[expected_failure(abort_code = dao_contract::ENOT_A_MEMBER)]
    fun test_renounce_membership(owner: signer, member: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&member));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&member);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member), 50000000);

        dao_contract::init_test_dao<FakeMoney>(&owner);
        dao_contract::apply_for_membership<FakeMoney>(&member, signer::address_of(&owner));
        assert!(dao_contract::is_member_test<FakeMoney>(&member), 101);

        dao_contract::renounce_membership<FakeMoney>(&member, signer::address_of(&owner), signer::address_of(&member));
        assert!(!dao_contract::is_member_test<FakeMoney>(&member), 102);
    }

    #[test(owner = @testing,  member = @0xAA, recipient = @0xAB, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_new_proposal(owner: signer, member: signer, recipient: signer, framework: signer) {  
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&member));
        account::create_account_for_test(signer::address_of(&recipient));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&member);
        coin::register<FakeMoney>(&recipient);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member), 50000000);

        dao_contract::init_test_dao<FakeMoney>(&owner);
        dao_contract::apply_for_membership<FakeMoney>(&member, signer::address_of(&owner));
        dao_contract::add_recipient<FakeMoney>(&owner, signer::address_of(&recipient));
        dao_contract::init_test_proposal<FakeMoney>(&member, signer::address_of(&owner), signer::address_of(&recipient));
        assert!(dao_contract::test_has_proposal<FakeMoney>(&member), 101);
    }

    #[test(owner = @testing,  member = @0xAA, recipient = @0xAB, framework = @aptos_framework)]
    #[expected_failure(abort_code = dao_contract::ESTILL_ACTIVE_VOTES)]
    fun test_renounce_membership_with_active_proposal_votes(owner: signer, member: signer, recipient: signer, framework: signer) {  
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&member));
        account::create_account_for_test(signer::address_of(&recipient));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&member);
        coin::register<FakeMoney>(&recipient);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member), 50000000);

        dao_contract::init_test_dao<FakeMoney>(&owner);
        dao_contract::apply_for_membership<FakeMoney>(&member, signer::address_of(&owner));
        dao_contract::add_recipient<FakeMoney>(&owner, signer::address_of(&recipient));
        dao_contract::init_test_proposal<FakeMoney>(&member, signer::address_of(&owner), signer::address_of(&recipient));
        dao_contract::renounce_membership<FakeMoney>(&member, signer::address_of(&owner), signer::address_of(&member));
    }

    #[test(owner = @testing,  member = @0xAA, member2 = @0x11, recipient = @0xAC, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_vote(owner: signer, member: signer, member2: signer,recipient: signer, framework: signer) {  
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&member));
        account::create_account_for_test(signer::address_of(&member2));
        account::create_account_for_test(signer::address_of(&recipient));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&member);
        coin::register<FakeMoney>(&member2);
        coin::register<FakeMoney>(&recipient);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member), 40000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member2), 10000000);

        dao_contract::init_test_dao<FakeMoney>(&owner);
        dao_contract::apply_for_membership<FakeMoney>(&member, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member2, signer::address_of(&owner));
        dao_contract::add_recipient<FakeMoney>(&owner, signer::address_of(&recipient));
        let id = dao_contract::init_test_proposal<FakeMoney>(&member, signer::address_of(&owner), signer::address_of(&recipient));
        dao_contract::cast_vote<FakeMoney>(&member2, signer::address_of(&owner), id, true);
    }

    #[test(owner = @testing,  member = @0xAA, member2 = @0x11, recipient = @0xAC, framework = @aptos_framework)]
    #[expected_failure(abort_code = dao_contract::ENO_PROPOSAL_WITH_ID)]
    fun test_vote_wrong_ID(owner: signer, member: signer, member2: signer,recipient: signer, framework: signer) {  
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&member));
        account::create_account_for_test(signer::address_of(&member2));
        account::create_account_for_test(signer::address_of(&recipient));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&member);
        coin::register<FakeMoney>(&member2);
        coin::register<FakeMoney>(&recipient);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member), 40000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member2), 10000000);

        dao_contract::init_test_dao<FakeMoney>(&owner);
        dao_contract::apply_for_membership<FakeMoney>(&member, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member2, signer::address_of(&owner));
        dao_contract::add_recipient<FakeMoney>(&owner, signer::address_of(&recipient));
        let _ = dao_contract::init_test_proposal<FakeMoney>(&member, signer::address_of(&owner), signer::address_of(&recipient));
        let id2 = 103;
        dao_contract::cast_vote<FakeMoney>(&member2, signer::address_of(&owner), id2, true);
    }

    #[test(owner = @testing,  member = @0xAA, member2 = @0x11, recipient = @0xAC, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_execution(owner: signer, member: signer, member2: signer,recipient: signer, framework: signer) {  
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&member));
        account::create_account_for_test(signer::address_of(&member2));
        account::create_account_for_test(signer::address_of(&recipient));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&member);
        coin::register<FakeMoney>(&member2);
        coin::register<FakeMoney>(&recipient);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member), 40000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member2), 10000000);

        dao_contract::init_test_dao<FakeMoney>(&owner);
        dao_contract::apply_for_membership<FakeMoney>(&member, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member2, signer::address_of(&owner));
        dao_contract::add_recipient<FakeMoney>(&owner, signer::address_of(&recipient));
        let proposal_id = dao_contract::init_test_proposal<FakeMoney>(&member, signer::address_of(&owner), signer::address_of(&recipient));
        dao_contract::cast_vote<FakeMoney>(&member2, signer::address_of(&owner), proposal_id, true);
        
        dao_contract::execute_proposal<FakeMoney>(&owner, proposal_id);

        assert!(coin::balance<FakeMoney>(signer::address_of(&recipient)) == 10000000, 101);
    }

    #[test(owner = @testing, member1 = @0x11, member2 = @0x12, member3 = @0x13, member4 = @0x14, recipient = @0xAC, framework = @aptos_framework)]
    #[expected_failure(abort_code = dao_contract::EPROPOSAL_NOT_APPROVED)]
    fun test_execution_without_the_votes(owner: signer, member1: signer, member2: signer,  member3: signer, member4: signer, recipient: signer, framework: signer) {  
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&member1));
        account::create_account_for_test(signer::address_of(&member2));
        account::create_account_for_test(signer::address_of(&member3));
        account::create_account_for_test(signer::address_of(&member4));
        account::create_account_for_test(signer::address_of(&recipient));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 120000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&member1);
        coin::register<FakeMoney>(&member2);
        coin::register<FakeMoney>(&member3);
        coin::register<FakeMoney>(&member4);
        coin::register<FakeMoney>(&recipient);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member1), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member2), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member3), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member4), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&recipient), 20000000);

        dao_contract::init_test_dao<FakeMoney>(&owner);

        dao_contract::apply_for_membership<FakeMoney>(&member1, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member2, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member3, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member4, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&recipient, signer::address_of(&owner));
        dao_contract::add_recipient<FakeMoney>(&owner, signer::address_of(&recipient));

        let proposal_id = dao_contract::init_test_proposal<FakeMoney>(&member1, signer::address_of(&owner), signer::address_of(&recipient));
        dao_contract::cast_vote<FakeMoney>(&member2, signer::address_of(&owner), proposal_id, true);
        
        dao_contract::execute_proposal<FakeMoney>(&owner, proposal_id); // There are 6 members, the voting threshold is 50% and only 2 have voted yes => can not execute!
    }

    #[test(owner = @testing, member1 = @0x11, member2 = @0x12, member3 = @0x13, member4 = @0x14, recipient = @0xAC, framework = @aptos_framework)]
    #[expected_failure(abort_code = dao_contract::EPROPOSAL_EXPIRED)]
    fun test_vote_after_closed(owner: signer, member1: signer, member2: signer,  member3: signer, member4: signer, recipient: signer, framework: signer) {  
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&member1));
        account::create_account_for_test(signer::address_of(&member2));
        account::create_account_for_test(signer::address_of(&member3));
        account::create_account_for_test(signer::address_of(&member4));
        account::create_account_for_test(signer::address_of(&recipient));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 120000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&member1);
        coin::register<FakeMoney>(&member2);
        coin::register<FakeMoney>(&member3);
        coin::register<FakeMoney>(&member4);
        coin::register<FakeMoney>(&recipient);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member1), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member2), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member3), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member4), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&recipient), 20000000);

        dao_contract::init_test_dao<FakeMoney>(&owner);

        dao_contract::apply_for_membership<FakeMoney>(&member1, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member2, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member3, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member4, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&recipient, signer::address_of(&owner));
        dao_contract::add_recipient<FakeMoney>(&owner, signer::address_of(&recipient));

        let proposal_id = dao_contract::init_test_proposal<FakeMoney>(&member1, signer::address_of(&owner), signer::address_of(&recipient));
        dao_contract::cast_vote<FakeMoney>(&member2, signer::address_of(&owner), proposal_id, true);
        
        dao_contract::close_proposal<FakeMoney>(&owner, proposal_id);
        dao_contract::cast_vote<FakeMoney>(&member3, signer::address_of(&owner), proposal_id, true);
    }

    #[test(owner = @testing, member1 = @0x11, member2 = @0x12, member3 = @0x13, member4 = @0x14, recipient = @0xAC, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_renounce_membership_after_closed(owner: signer, member1: signer, member2: signer,  member3: signer, member4: signer, recipient: signer, framework: signer) {  
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&member1));
        account::create_account_for_test(signer::address_of(&member2));
        account::create_account_for_test(signer::address_of(&member3));
        account::create_account_for_test(signer::address_of(&member4));
        account::create_account_for_test(signer::address_of(&recipient));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 120000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&member1);
        coin::register<FakeMoney>(&member2);
        coin::register<FakeMoney>(&member3);
        coin::register<FakeMoney>(&member4);
        coin::register<FakeMoney>(&recipient);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member1), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member2), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member3), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member4), 20000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&recipient), 20000000);

        dao_contract::init_test_dao<FakeMoney>(&owner);

        dao_contract::apply_for_membership<FakeMoney>(&member1, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member2, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member3, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member4, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&recipient, signer::address_of(&owner));
        dao_contract::add_recipient<FakeMoney>(&owner, signer::address_of(&recipient));

        let proposal_id = dao_contract::init_test_proposal<FakeMoney>(&member1, signer::address_of(&owner), signer::address_of(&recipient));
        dao_contract::cast_vote<FakeMoney>(&member2, signer::address_of(&owner), proposal_id, true);
        
        dao_contract::close_proposal<FakeMoney>(&owner, proposal_id);
        dao_contract::renounce_membership<FakeMoney>(&member1, signer::address_of(&owner), signer::address_of(&member1));
    }

    #[test(owner = @testing,  member1 = @0xAA, member2 = @0x11, recipient = @0xAC, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_destruction(owner: signer, member1: signer, member2: signer,recipient: signer, framework: signer) {  
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::update_global_time_for_test(11000000);
        
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&member1));
        account::create_account_for_test(signer::address_of(&member2));
        account::create_account_for_test(signer::address_of(&recipient));
        account::create_account_for_test(signer::address_of(&framework));

        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &owner, totalMoney);
        coin::register<FakeMoney>(&owner);
        coin::register<FakeMoney>(&member1);
        coin::register<FakeMoney>(&member2);
        coin::register<FakeMoney>(&recipient);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&owner), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member1), 40000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&member2), 10000000);

        dao_contract::init_test_dao<FakeMoney>(&owner);
        dao_contract::apply_for_membership<FakeMoney>(&member1, signer::address_of(&owner));
        dao_contract::apply_for_membership<FakeMoney>(&member2, signer::address_of(&owner));
        dao_contract::add_recipient<FakeMoney>(&owner, signer::address_of(&recipient));
        let proposal_id = dao_contract::init_test_proposal<FakeMoney>(&member1, signer::address_of(&owner), signer::address_of(&recipient));
        dao_contract::cast_vote<FakeMoney>(&member2, signer::address_of(&owner), proposal_id, true);
        
        dao_contract::execute_proposal<FakeMoney>(&owner, proposal_id);
        dao_contract::destroy_dao<FakeMoney>(&owner);

        assert!(!dao_contract::is_owner_test<FakeMoney>(&owner), 101);
        assert!(!dao_contract::is_member_test<FakeMoney>(&member1), 102);
        assert!(!dao_contract::is_member_test<FakeMoney>(&member2), 103);
    }
}