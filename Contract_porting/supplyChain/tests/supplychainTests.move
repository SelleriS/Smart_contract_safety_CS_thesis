#[test_only]
module testing::supplychain_tests{
    use testing::supplychain;
    use aptos_framework::account;
    use std::signer;
    use aptos_framework::coin::{Self, FakeMoney};

    #[test(owner = @testing, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_initialise(owner: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&framework));

        supplychain::initialise_supplychain<FakeMoney>(&owner);

        assert!(supplychain::is_owner_test<FakeMoney>(&owner), 101);
    }

    #[test(owner = @testing,  new_owner = @0xAA, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_ownership_transfer(owner: signer, new_owner: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&new_owner));
        account::create_account_for_test(signer::address_of(&framework));

        supplychain::initialise_supplychain<FakeMoney>(&owner);
        supplychain::initiate_ownership_transfer<FakeMoney>(&owner, signer::address_of(&new_owner));
        assert!(supplychain::is_owner_test<FakeMoney>(&owner), 101);

        supplychain::transfer_ownership<FakeMoney>(&new_owner, signer::address_of(&owner));
        assert!(supplychain::is_owner_test<FakeMoney>(&new_owner), 102);
    }

    #[test(owner = @testing,  farmer = @0xAA, distributor = @0xAB, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_access_control(owner: signer, farmer: signer, distributor: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&farmer));
        account::create_account_for_test(signer::address_of(&distributor));
        account::create_account_for_test(signer::address_of(&framework));

        supplychain::initialise_supplychain<FakeMoney>(&owner);

        supplychain::apply_for_farmer(&farmer);
        supplychain::approve_farmer<FakeMoney>(&owner, signer::address_of(&farmer));

        supplychain::apply_for_distributor(&distributor);
        supplychain::approve_distributor<FakeMoney>(&owner, signer::address_of(&distributor));

        assert!(supplychain::is_farmer(&farmer),101);
        assert!(supplychain::is_distributor(&distributor),102);
    }

    #[test(owner = @testing,  farmer = @0xAA, framework = @aptos_framework)]
    #[expected_failure]
    fun test_farmer_activities(owner: signer, farmer: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&farmer));
        account::create_account_for_test(signer::address_of(&framework));

        // Init supplychain and roles
        supplychain::initialise_supplychain<FakeMoney>(&owner);
        supplychain::apply_for_farmer(&farmer);
        supplychain::approve_farmer<FakeMoney>(&owner, signer::address_of(&farmer));

        // Farmer activities
        let upc = 911;
        let upc2 = 112;
        let price = 10000000;
        supplychain::harvest_item<FakeMoney>(&farmer, signer::address_of(&owner), upc);
        supplychain::process_item<FakeMoney>(&farmer, signer::address_of(&owner), upc);
        supplychain::pack_item<FakeMoney>(&farmer, signer::address_of(&owner), upc2); //<== Should fail because item upc2 does not yet exist
        supplychain::sell_item<FakeMoney>(&farmer, signer::address_of(&owner), upc, price);
    }

    #[test(owner = @testing,  farmer = @0xAA, distributor = @0xAB, retailer = @0xAC, consumer = @0xAD, framework = @aptos_framework)]
    //#[expected_failure(abort_code = )]
    fun test_supplychain(owner: signer, farmer: signer, distributor: signer, retailer: signer, consumer: signer, framework: signer) {  
        account::create_account_for_test(signer::address_of(&owner));
        account::create_account_for_test(signer::address_of(&farmer));
        account::create_account_for_test(signer::address_of(&distributor));
        account::create_account_for_test(signer::address_of(&retailer));
        account::create_account_for_test(signer::address_of(&consumer));
        account::create_account_for_test(signer::address_of(&framework));

        // Creating FakeMoney coins and registering them in the accounts that have to be able to handle (contain) them
        let totalMoney = 100000000u64; //100.000.000 octas = 1 APT
        coin::create_fake_money(&framework, &farmer, totalMoney);
        coin::register<FakeMoney>(&distributor);
        //coin::register<FakeMoney>(&consumer);

        // Allocating the FakeMoney coins to each donor account
        coin::transfer<FakeMoney>(&framework, signer::address_of(&farmer), 50000000);
        coin::transfer<FakeMoney>(&framework, signer::address_of(&distributor), 50000000);


        // Init supplychain and roles
        supplychain::initialise_supplychain<FakeMoney>(&owner);

        supplychain::apply_for_farmer(&farmer);
        supplychain::approve_farmer<FakeMoney>(&owner, signer::address_of(&farmer));

        supplychain::apply_for_distributor(&distributor);
        supplychain::approve_distributor<FakeMoney>(&owner, signer::address_of(&distributor));

        supplychain::apply_for_retailer(&retailer);
        supplychain::approve_retailer<FakeMoney>(&owner, signer::address_of(&retailer));

        supplychain::apply_for_consumer(&consumer);
        supplychain::approve_consumer<FakeMoney>(&owner, signer::address_of(&consumer));

        
        // Farmer activities
        let upc = 911;
        let price = 10000000;
        supplychain::harvest_item<FakeMoney>(&farmer, signer::address_of(&owner), upc);
        supplychain::process_item<FakeMoney>(&farmer, signer::address_of(&owner), upc);
        supplychain::pack_item<FakeMoney>(&farmer, signer::address_of(&owner), upc);
        supplychain::sell_item<FakeMoney>(&farmer, signer::address_of(&owner), upc, price);
        
        // Distributor activities
        let amount = 10000100;
        supplychain::buy_item<FakeMoney>(&distributor, signer::address_of(&owner), signer::address_of(&farmer), upc, amount);
        supplychain::ship_item<FakeMoney>(&distributor, signer::address_of(&owner), upc);

        // Retailer acitivities
        supplychain::receive_item<FakeMoney>(&retailer, signer::address_of(&owner), signer::address_of(&distributor), upc);

        // Consumer acitivities
        supplychain::purchase_item<FakeMoney>(&consumer, signer::address_of(&owner), signer::address_of(&retailer), upc);
    }
}