module testing::supplychain{
    use testing::roles::{Self, FarmerRole, DistributorRole, RetailerRole, ConsumerRole};
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::coin;
    use aptos_std::table_with_length::{Self, TableWithLength};
    
//ERROR CODES
    const EONLY_DEPLOYER_CAN_INITIALIZE: u64 = 0; 
    const ENO_SUPPLY_CHAIN_AT_ADDRESS: u64 = 1;
    const EONLY_OWNER_CAN_CALL: u64 = 2;
    const ETRANSFER_NOT_APPROVED_BY_OWNER: u64 = 3;
    const EONLY_OWNER_OR_APPLICANT_CAN_CALL: u64 = 4;
    const EAPPLICANT_DOES_NOT_HAVE_ROLE_RESOURCE: u64 = 5;
    const ENO_ITEMSTORE: u64 = 6;
    const EITEMSTORE_NOT_EMPTY: u64 = 7;
    const EINCORRECT_ROLE: u64 = 8;
    const ESTATE_DOES_NOT_MATCH: u64 = 9;
    const EPAYMENT_TOO_LOW: u64 = 10;
    const ENO_SUFFICIENT_FUND:u64 = 11;

//STRUCTS
    struct SupplyChain<phantom CoinType> has key {
        new_owner: address,
        sku: u64, // Stock Keeping Unit
    }

    struct Item has store {
        sku: u64,
        upc: u64, // Universal product code provided by farmer
        farmer_ID: address, // address of the Farmer
        distributor_ID: address,  // address of the Distributor
        retailer_ID: address, // address of the Retailer
        consumer_ID: address, // address of the Consumer
        price: u64,
        state: u8,
    }

    struct ItemStore<phantom RoleType> has key {
        items: TableWithLength<u64, Item>,
        state_change_events: EventHandle<StateChangeEvent>,
    }

    struct StateChangeEvent has drop, store {
        new_state: u8,
    }

//OWNERSHIP
    public entry fun initialise_supplychain<CoinType>(owner: &signer) {
        let owner_address = signer::address_of(owner);
        assert!(owner_address == @testing, EONLY_DEPLOYER_CAN_INITIALIZE);
        move_to(
            owner,
            SupplyChain<CoinType> {
                new_owner: owner_address,
                sku: 1,
            }
        );
    }

    public entry fun initiate_ownership_transfer<CoinType>(owner: &signer, new_owner_address: address) acquires SupplyChain{
        only_owner<CoinType>(owner);
        let new_owner = &mut borrow_global_mut<SupplyChain<CoinType>>(signer::address_of(owner)).new_owner;
        *new_owner = new_owner_address;
    }

    public entry fun transfer_ownership<CoinType>(new_owner: &signer, owner_address: address) acquires SupplyChain{
        only_if_supplychain<CoinType>(owner_address);

        // Check if the new owner address in the supplychain resource is equal to the new_owner that is trying to transfer
        let sc = borrow_global<SupplyChain<CoinType>>(owner_address);
        assert!(sc.new_owner == signer::address_of(new_owner), ETRANSFER_NOT_APPROVED_BY_OWNER);
        
        move_to<SupplyChain<CoinType>>(new_owner, move_from<SupplyChain<CoinType>>(owner_address));
    }

    fun only_if_supplychain<CoinType>(supply_chain_address: address){
        assert!(exists<SupplyChain<CoinType>>(supply_chain_address), ENO_SUPPLY_CHAIN_AT_ADDRESS);
    }

    fun only_owner<CoinType>(owner: &signer) {
        assert!(exists<SupplyChain<CoinType>>(signer::address_of(owner)), EONLY_OWNER_CAN_CALL);
    }

    fun only_role<RoleType>(applicant: &signer) {
        assert!(roles::is_account_approved_for_role<RoleType>(signer::address_of(applicant)), EINCORRECT_ROLE);
    }

//ITEMSSTORE
    fun only_if_itemstore<RoleType>(account_address: address){
        assert!(exists<ItemStore<RoleType>>(account_address), ENO_ITEMSTORE);
    }

    fun create_and_store_itemstore<RoleType>(account: &signer) {
        move_to(
            account, 
            ItemStore<RoleType> {
                items: table_with_length::new<u64, Item>(),
                state_change_events: account::new_event_handle<StateChangeEvent>(account)
            }
        );
    }

    fun remove_item_store<RoleType>(account_address: address) acquires ItemStore {
        only_if_itemstore<RoleType>(account_address);
        let ItemStore<RoleType>{
            items: items_table,
            state_change_events: state_change_event_handle,
        } = move_from<ItemStore<RoleType>>(account_address);
        table_with_length::destroy_empty(items_table);
        event::destroy_handle(state_change_event_handle);
    }

    fun add_to_itemstore<RoleType>(account_address: address, upc: u64, item: Item) acquires ItemStore {
        only_if_itemstore<RoleType>(account_address);
        let items = &mut borrow_global_mut<ItemStore<RoleType>>(account_address).items;
        table_with_length::add(items, upc, item);
    }

    fun transfer_between_itemstores<RoleType1, RoleType2>(account_address_from: address, account_address_to: address, upc: u64) acquires ItemStore {
        only_if_itemstore<RoleType1>(account_address_from);
        only_if_itemstore<RoleType2>(account_address_to);
        let items_from = &mut borrow_global_mut<ItemStore<RoleType1>>(account_address_from).items;
        let item = table_with_length::remove(items_from, upc);
        let items_to = &mut borrow_global_mut<ItemStore<RoleType2>>(account_address_to).items; //This line had to be switched with the previous one to prevent "mutable ownership violation": WHY?
        table_with_length::add(items_to, upc, item);
    }

//ITEM
    fun check_item_state<RoleType>(account_address: address, upc: u64, current_state: u8) acquires ItemStore {
        let items = & borrow_global<ItemStore<RoleType>>(account_address).items;
        let state = & table_with_length::borrow(items, upc).state;
        assert!(*state == current_state, ESTATE_DOES_NOT_MATCH);
    }

    //Add event emmission!
    fun check_and_update_item_state<RoleType>(account: &signer, upc: u64, current_state: u8, new_state: u8) acquires ItemStore {
        let store = borrow_global_mut<ItemStore<RoleType>>(signer::address_of(account));
        let items = &mut store.items;
        let state = &mut table_with_length::borrow_mut(items, upc).state;
        assert!(*state == current_state, ESTATE_DOES_NOT_MATCH);
        *state = new_state;
        event::emit_event<StateChangeEvent>(
            &mut store.state_change_events,
            StateChangeEvent { new_state: new_state },
        );
    }

//FARMER
    public entry fun apply_for_farmer(account: &signer) {
        roles::apply_for_role<FarmerRole>(account);
        create_and_store_itemstore<FarmerRole>(account);
    }

    public entry fun approve_farmer<CoinType>(owner: &signer, applicant_address: address) {
        only_owner<CoinType>(owner);
        roles::approve_account<FarmerRole>(applicant_address);
    }

    public entry fun remove_farmer<CoinType>(authenticator: &signer, applicant_address: address) acquires ItemStore {
        let is_owner = exists<SupplyChain<CoinType>>(signer::address_of(authenticator));
        let is_applicant = (signer::address_of(authenticator) == applicant_address);
        assert!(is_owner || is_applicant, EONLY_OWNER_OR_APPLICANT_CAN_CALL);
        roles::is_account_approved_for_role<FarmerRole>(applicant_address);
        
        remove_item_store<FarmerRole>(applicant_address);
        roles::remove_account<FarmerRole>(applicant_address);
    }

//DISTRIBUTOR
    public entry fun apply_for_distributor(account: &signer) {
        roles::apply_for_role<DistributorRole>(account);
        create_and_store_itemstore<DistributorRole>(account);
    }

    public entry fun approve_distributor<CoinType>(owner: &signer, applicant_address: address) {
        only_owner<CoinType>(owner);
        roles::approve_account<DistributorRole>(applicant_address);
    }

    public entry fun remove_distributor<CoinType>(authenticator: &signer, applicant_address: address) acquires ItemStore {
        let is_owner = exists<SupplyChain<CoinType>>(signer::address_of(authenticator));
        let is_applicant = (signer::address_of(authenticator) == applicant_address);
        assert!(is_owner || is_applicant, EONLY_OWNER_OR_APPLICANT_CAN_CALL);
        roles::is_account_approved_for_role<DistributorRole>(applicant_address);
        
        remove_item_store<DistributorRole>(applicant_address);
        roles::remove_account<DistributorRole>(applicant_address);
    }

//RETAILERS
    public entry fun apply_for_retailer(account: &signer) {
        roles::apply_for_role<RetailerRole>(account);
        create_and_store_itemstore<RetailerRole>(account);
    }

    public entry fun approve_retailer<CoinType>(owner: &signer, applicant_address: address) {
        only_owner<CoinType>(owner);
        roles::approve_account<RetailerRole>(applicant_address);
    }

    public entry fun remove_retailer<CoinType>(authenticator: &signer, applicant_address: address) acquires ItemStore {
        let is_owner = exists<SupplyChain<CoinType>>(signer::address_of(authenticator));
        let is_applicant = (signer::address_of(authenticator) == applicant_address);
        assert!(is_owner || is_applicant, EONLY_OWNER_OR_APPLICANT_CAN_CALL);
        roles::is_account_approved_for_role<RetailerRole>(applicant_address);
        
        remove_item_store<RetailerRole>(applicant_address);
        roles::remove_account<RetailerRole>(applicant_address);
    }

//CONSUMERS
    public entry fun apply_for_consumer(account: &signer) {
        roles::apply_for_role<ConsumerRole>(account);
        create_and_store_itemstore<ConsumerRole>(account);
    }

    public entry fun approve_consumer<CoinType>(owner: &signer, applicant_address: address) {
        only_owner<CoinType>(owner);
        roles::approve_account<ConsumerRole>(applicant_address);
    }

    public entry fun remove_consumer<CoinType>(authenticator: &signer, applicant_address: address) acquires ItemStore {
        let is_owner = exists<SupplyChain<CoinType>>(signer::address_of(authenticator));
        let is_applicant = (signer::address_of(authenticator) == applicant_address);
        assert!(is_owner || is_applicant, EONLY_OWNER_OR_APPLICANT_CAN_CALL);
        roles::is_account_approved_for_role<ConsumerRole>(applicant_address);

        remove_item_store<ConsumerRole>(applicant_address);
        roles::remove_account<ConsumerRole>(applicant_address);
    }

//SUPPLYCHAIN FUNCTIONS
    public entry fun harvest_item<CoinType>(farmer: &signer, supply_chain_address:address, upc: u64) acquires SupplyChain, ItemStore{
        only_if_supplychain<CoinType>(supply_chain_address);
        only_role<FarmerRole>(farmer);
        let farmer_address = signer::address_of(farmer);
        let sku = &mut borrow_global_mut<SupplyChain<CoinType>>(supply_chain_address).sku;
        add_to_itemstore<FarmerRole> (
            farmer_address, 
            upc, 
            Item{
                sku: *sku,
                upc: upc,
                farmer_ID: farmer_address,
                distributor_ID: @0x0,
                retailer_ID: @0x0,
                consumer_ID: @0x0,
                price: 0,
                state: 0,
            }
        );
        *sku = *sku + 1;
    }

    public entry fun process_item<CoinType>(farmer: &signer, supply_chain_address: address, upc: u64) acquires ItemStore{
        only_if_supplychain<CoinType>(supply_chain_address);
        only_role<FarmerRole>(farmer);
        check_and_update_item_state<FarmerRole>(farmer, upc, 0, 1);
    }

    public entry fun pack_item<CoinType>(farmer: &signer, supply_chain_address: address, upc: u64) acquires ItemStore{
        only_if_supplychain<CoinType>(supply_chain_address);
        only_role<FarmerRole>(farmer);
        check_and_update_item_state<FarmerRole>(farmer, upc, 1, 2);
    }

    public entry fun sell_item<CoinType>(farmer: &signer, supply_chain_address:address, upc: u64, price: u64) acquires ItemStore{
        only_if_supplychain<CoinType>(supply_chain_address);
        only_role<FarmerRole>(farmer);
        let farmer_address = signer::address_of(farmer);
        check_item_state<FarmerRole>(farmer_address, upc, 2);

        let items = &mut borrow_global_mut<ItemStore<FarmerRole>>(farmer_address).items;
        let itemprice = &mut table_with_length::borrow_mut(items, upc).price;
        *itemprice = price;
        check_and_update_item_state<FarmerRole>(farmer, upc, 2, 3);
    }

    public entry fun buy_item<CoinType>(distributor: &signer, supply_chain_address: address, farmer_address: address, upc: u64, amount: u64) acquires ItemStore{
        only_if_supplychain<CoinType>(supply_chain_address);
        only_role<DistributorRole>(distributor);
        check_item_state<FarmerRole>(farmer_address, upc, 3);
        
        //Check if amount > price
        let items = &mut borrow_global_mut<ItemStore<FarmerRole>>(farmer_address).items;
        let price = & table_with_length::borrow_mut(items, upc).price;
        assert!(amount >= *price, EPAYMENT_TOO_LOW);
        
        //Check if buyer_balance > amount)
        let distributor_address = signer::address_of(distributor);
        assert!(coin::balance<CoinType>(distributor_address) >= *price, ENO_SUFFICIENT_FUND);
        
        //Transfer coins
        let coins = coin::withdraw<CoinType>(distributor, *price);
        coin::deposit(farmer_address, coins);
        
        //Transfer item
        transfer_between_itemstores<FarmerRole, DistributorRole>(farmer_address, distributor_address, upc);
        
        //Update distributorID field in Item
        let items = &mut borrow_global_mut<ItemStore<DistributorRole>>(distributor_address).items;
        let distributor_ID = &mut table_with_length::borrow_mut(items, upc).distributor_ID;
        *distributor_ID = distributor_address;

        //Update state
        check_and_update_item_state<DistributorRole>(distributor, upc, 3, 4);
    }

    public entry fun ship_item<CoinType>(distributor: &signer, supply_chain_address: address, upc: u64) acquires ItemStore{
        only_if_supplychain<CoinType>(supply_chain_address);
        only_role<DistributorRole>(distributor);
        check_and_update_item_state<DistributorRole>(distributor, upc, 4, 5);
    }

    public entry fun receive_item<CoinType>(retailer: &signer, supply_chain_address: address, distributor_address: address, upc: u64) acquires ItemStore{
        only_if_supplychain<CoinType>(supply_chain_address);
        only_role<RetailerRole>(retailer);        
        check_item_state<DistributorRole>(distributor_address, upc, 5);

        //Transfer item
        let retailer_address = signer::address_of(retailer);
        transfer_between_itemstores<DistributorRole, RetailerRole>(distributor_address, retailer_address, upc);
        
        //Update retailerID field in Item
        let items = &mut borrow_global_mut<ItemStore<RetailerRole>>(retailer_address).items;
        let retailer_ID = &mut table_with_length::borrow_mut(items, upc).retailer_ID;
        *retailer_ID = retailer_address;
        
        //Update state
        check_and_update_item_state<RetailerRole>(retailer, upc, 5, 6);
    }

    public entry fun purchase_item<CoinType>(consumer: &signer, supply_chain_address: address, retailer_address: address, upc: u64) acquires ItemStore{
        only_if_supplychain<CoinType>(supply_chain_address);
        only_role<ConsumerRole>(consumer);
        check_item_state<RetailerRole>(retailer_address, upc, 6);
        
        //Transfer item
        let consumer_address = signer::address_of(consumer);
        transfer_between_itemstores<RetailerRole, ConsumerRole>(retailer_address, consumer_address, upc);
        
        //Update consumerID field in Item
        let items = &mut borrow_global_mut<ItemStore<ConsumerRole>>(consumer_address).items;
        let consumer_ID = &mut table_with_length::borrow_mut(items, upc).consumer_ID;
        *consumer_ID = consumer_address;
        
        //Update state
        check_and_update_item_state<ConsumerRole>(consumer, upc, 6, 7);
    }



//TESTS
    //INIT TEST FUNCTION
    #[test_only]
    public entry fun is_owner_test<CoinType>(owner: &signer): bool {
        exists<SupplyChain<CoinType>>(signer::address_of(owner))
    }
    //ACCESS CONTROL TEST FUNCTIONS
    #[test_only]
    public entry fun is_farmer(applicant: &signer): bool {
        roles::is_account_approved_for_role<FarmerRole>(signer::address_of(applicant))
    }

    #[test_only]
    public entry fun is_distributor(applicant: &signer): bool {
        roles::is_account_approved_for_role<DistributorRole>(signer::address_of(applicant))
    }

}