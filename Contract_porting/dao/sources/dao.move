module testing::dao_contract{
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::coin::{Self, Coin};
    use aptos_std::table_with_length::{Self, TableWithLength};
    
//ERROR CODES
    const EONLY_DEPLOYER_CAN_INITIALIZE: u64 = 0; 
    const ENO_DAO_AT_ADDRESS: u64 = 1;
    const EONLY_OWNER_CAN_CALL: u64 = 2;
    const ETRANSFER_NOT_APPROVED_BY_OWNER: u64 = 3;
    const EALREADY_MEMBER: u64 = 4;
    const ENOT_A_MEMBER: u64 = 5;
    const ENO_SUFFICIENT_FUND: u64 = 6;
    const EONLY_OWNER_OR_MEMBER_CAN_CALL: u64 = 7;
    const ESTILL_ACTIVE_PROPOSALS: u64 = 8;
    const ERECIPIENT_NOT_WHITELISTED: u64 = 9;
    const EALREADY_VOTED: u64 = 10;
    const EPROPOSAL_EXPIRED: u64 = 11;
    const EPROPOSAL_DEADLINE_PASSED: u64 = 12;
    const EPROPOSAL_NOT_APPROVED: u64 = 13;
    const ENOT_ENOUGH_FUNDS_IN_DAO: u64 = 14;
    const EPROPOSAL_DEADLINE_NOT_REACHED: u64 = 15;
    const ERECIPIENT_ALREADY_ADDED: u64 = 16;
    const ENO_SUCH_RECIPIENT: u64 = 17;
    const EPROPOSAL_IS_APPROVED: u64 = 18;
    const ESTILL_ACTIVE_VOTES: u64 = 19;
    const ENO_PROPOSAL_WITH_ID: u64 = 20;


//CONSTANTS
    const MINUTE_CONVERSION_FACTOR: u64 =  60;

    struct DAO<phantom CoinType> has key {
        new_owner: address,
        sku: u64, // Stock Keeping Unit
        min_investment: u64, //minimum stake an individual has to commit to become a member
        min_voting_percentage: u64,
        min_voting_time: u64,
        min_proposal_deposit: u64,
        whitelisted_recipients: vector<address>,
        proposal_addresses: TableWithLength<u64, address>,
        investors: vector<address>,
        n_members: u64,
        funds: Coin<CoinType>,
        executed_event: EventHandle<ExecutedEvent>,
        closed_event: EventHandle<ClosedEvent>,
    }

    struct Proposal<phantom CoinType> has store {
        id: u64,
        recipient: address,
        investment: u64,
        deadline: u64,
        active: bool,
        approved: bool,
        approval_threshold: u64,
        deposit: Coin<CoinType>,
        n_yes: u64,
        n_no: u64,
        voted: vector<address>,
    }

    struct DAO_member<phantom CoinType> has key {
        n_total_proposals: u64,
        invested_balance: u64,
        active_proposals: TableWithLength<u64, Proposal<CoinType>>,
        voted_event: EventHandle<VotedEvent>,
        proposal_added_event: EventHandle<ProposalAddedEvent>,
        //active_votes: vector<u64>,
    }

    struct ExecutedEvent has drop, store {
        proposal_id: u64,
        amount_invested: u64,
    }

    struct ClosedEvent has drop, store {
        proposal_id: u64,
    }

    struct VotedEvent has drop, store {
        proposal_id: u64,
        vote: bool,
    }

    struct ProposalAddedEvent has drop, store {
        proposal_id: u64,
        recipient: address,
        investment: u64,
    }

//DAO
    public entry fun initialise_DAO<CoinType>(owner: &signer, min_investment: u64, min_voting_percentage: u64, min_voting_time: u64, proposal_deposit: u64) {
        let owner_address = signer::address_of(owner);
        assert!(owner_address == @testing, EONLY_DEPLOYER_CAN_INITIALIZE);
        assert!(coin::balance<CoinType>(owner_address) >= (min_investment), ENO_SUFFICIENT_FUND);
        let coins_to_invest = coin::withdraw<CoinType>(owner, min_investment);

        move_to(
            owner,
            DAO<CoinType> {
                new_owner: owner_address,
                sku: 1,
                min_investment: min_investment,
                min_voting_percentage: min_voting_percentage, //int that will be used to calculate if a proposal has the right amount of votes
                min_voting_time: min_voting_time,
                min_proposal_deposit:proposal_deposit,
                whitelisted_recipients: vector::empty<address>(),
                proposal_addresses: table_with_length::new<u64, address>(),
                investors: vector::empty<address>(),
                n_members: 1,
                funds: coins_to_invest,
                executed_event: account::new_event_handle<ExecutedEvent>(owner),
                closed_event: account::new_event_handle<ClosedEvent>(owner),
            }
        );

        move_to(
            owner, 
            DAO_member<CoinType>{
                n_total_proposals: 0,
                invested_balance: min_investment,
                active_proposals: table_with_length::new<u64, Proposal<CoinType>>(),
                voted_event: account::new_event_handle<VotedEvent>(owner),
                proposal_added_event: account::new_event_handle<ProposalAddedEvent>(owner),
                //active_votes: vector::empty<u64>(),
            }
        );
    }

    public entry fun initiate_ownership_transfer<CoinType>(owner: &signer, new_owner_address: address) acquires DAO{
        only_owner<CoinType>(owner);
        assert!(exists<DAO_member<CoinType>>(new_owner_address), ENOT_A_MEMBER);
        let new_owner = &mut borrow_global_mut<DAO<CoinType>>(signer::address_of(owner)).new_owner;
        *new_owner = new_owner_address;
    }

    public entry fun transfer_ownership<CoinType>(new_owner: &signer, owner_address: address) acquires DAO{
        only_if_dao<CoinType>(owner_address);
        only_member<CoinType>(new_owner);
        
        let dao = borrow_global<DAO<CoinType>>(owner_address);
        assert!(dao.new_owner == signer::address_of(new_owner), ETRANSFER_NOT_APPROVED_BY_OWNER);
        
        move_to<DAO<CoinType>>(new_owner, move_from<DAO<CoinType>>(owner_address));
    }

    fun only_owner<CoinType>(owner: &signer) {
        assert!(exists<DAO<CoinType>>(signer::address_of(owner)), EONLY_OWNER_CAN_CALL);
    }

    fun only_if_dao<CoinType>(dao_address: address){
        assert!(exists<DAO<CoinType>>(dao_address), ENO_DAO_AT_ADDRESS);
    }

    public entry fun add_recipient<CoinType>(owner: &signer, recipient: address) acquires DAO {
        only_owner<CoinType>(owner);
        let dao = borrow_global_mut<DAO<CoinType>>(signer::address_of(owner));
        assert!(!vector::contains(& dao.whitelisted_recipients, & recipient), ERECIPIENT_ALREADY_ADDED);
        vector::push_back(&mut dao.whitelisted_recipients, recipient);
    }

    public entry fun remove_recipient<CoinType>(owner: &signer, recipient: address) acquires DAO {
        only_owner<CoinType>(owner);
        let dao = borrow_global_mut<DAO<CoinType>>(signer::address_of(owner));
        assert!(!vector::contains(& dao.whitelisted_recipients, & recipient), ENO_SUCH_RECIPIENT);
        let (_, index) = vector::index_of(& dao.whitelisted_recipients, & recipient);
        vector::remove(&mut dao.whitelisted_recipients, index);
    }

//MEMBERSHIP
    fun only_member<CoinType>(account: &signer) {
        assert!(exists<DAO_member<CoinType>>(signer::address_of(account)), ENOT_A_MEMBER);
    }

    public entry fun apply_for_membership<CoinType>(account: &signer, dao_address: address) acquires DAO {
        only_if_dao<CoinType>(dao_address);
        let account_address = signer::address_of(account);
        assert!(!exists<DAO_member<CoinType>>(account_address), EALREADY_MEMBER);
        let dao = borrow_global_mut<DAO<CoinType>>(dao_address);
        let min_investment = dao.min_investment;
        assert!(coin::balance<CoinType>(account_address) >= (min_investment), ENO_SUFFICIENT_FUND);
        
        let coins_to_invest = coin::withdraw<CoinType>(account, min_investment);
        let funds = &mut dao.funds;
        coin::merge<CoinType>(funds, coins_to_invest);
        
        move_to(
            account, 
            DAO_member<CoinType>{
                n_total_proposals: 0,
                invested_balance: min_investment,
                active_proposals: table_with_length::new<u64, Proposal<CoinType>>(),
                voted_event: account::new_event_handle<VotedEvent>(account),
                proposal_added_event: account::new_event_handle<ProposalAddedEvent>(account),
                //active_votes: vector::empty<u64>(),
            }
        );
        let n_members = &mut dao.n_members;
        *n_members = *n_members + 1;

    }

    public entry fun renounce_membership<CoinType>(authenticator: &signer, dao_address: address, member_address: address) acquires DAO, DAO_member {
        let authenticator_address = signer::address_of(authenticator);
        let is_owner = exists<DAO<CoinType>>(authenticator_address);
        let is_member = (signer::address_of(authenticator) == member_address);
        assert!(is_owner || is_member, EONLY_OWNER_OR_MEMBER_CAN_CALL);
        assert!(exists<DAO_member<CoinType>>(member_address), ENOT_A_MEMBER);
        //Member should not have any own active proposals
        assert!(table_with_length::empty(& borrow_global<DAO_member<CoinType>>(member_address).active_proposals), ESTILL_ACTIVE_PROPOSALS); 
        //Future feature: Keep track of active votes
        // Member shouldn't have any active votes => this prevents people from voting against the best interest of the DAO and then bailing before the change is implemented
        //assert!(vector::is_empty(& borrow_global<DAO_member<CoinType>>(member_address).active_votes), ESTILL_ACTIVE_VOTES);

        //Remove membership
        let dao = borrow_global_mut<DAO<CoinType>>(dao_address);
        let funds = &mut dao.funds;
        let reimburse_amount = coin::value<CoinType>(funds)/dao.n_members;
        let reimburse_coins = coin::extract<CoinType>(funds, reimburse_amount);
        coin::deposit<CoinType>(member_address, reimburse_coins);
        let DAO_member<CoinType>{
            n_total_proposals: _,
            invested_balance: _,
            active_proposals: proposals_table,
            voted_event: voted_event,
            proposal_added_event: proposal_added_event,
            //active_votes: votes_vector,
            } = move_from<DAO_member<CoinType>>(member_address);
        table_with_length::destroy_empty<u64, Proposal<CoinType>>(proposals_table);
        event::destroy_handle(voted_event);
        event::destroy_handle(proposal_added_event);
        //vector::destroy_empty<u64>(votes_vector);

        let n_members = &mut dao.n_members;
        *n_members = *n_members - 1;
    }

//PROPOSAL
    fun add_proposal_to_member<CoinType>(member_address: address, id: u64, proposal: Proposal<CoinType>) acquires DAO_member {
        let dao_member = borrow_global_mut<DAO_member<CoinType>>(member_address);
        let active_proposals = &mut dao_member.active_proposals;
        table_with_length::add(active_proposals, id, proposal);

        //Future feature: keep track of active votes
        //let active_votes = &mut dao_member.active_votes;
        //vector::push_back(active_votes, id);
    }

    public entry fun new_proposal<CoinType>(member: &signer, dao_address: address, recipient: address, investment: u64, debating_time: u64) acquires DAO, DAO_member {
        only_member<CoinType>(member);
        only_if_dao<CoinType>(dao_address);
        let member_address = signer::address_of(member);
        let dao = borrow_global_mut<DAO<CoinType>>(dao_address);

        //Check recipient is whitelisted
        let whitelisted = & dao.whitelisted_recipients;
        assert!(vector::contains(whitelisted, & recipient), ERECIPIENT_NOT_WHITELISTED);
        
        //Check if member has enough for a proposal deposit
        let min_proposal_deposit = dao.min_proposal_deposit;
        assert!(coin::balance<CoinType>(member_address) >= (min_proposal_deposit), ENO_SUFFICIENT_FUND);
        let proposal_deposit = coin::withdraw<CoinType>(member, min_proposal_deposit);

        //Check if debating time is more than the minimum otherwise attribute the minimum time
        let deadline = timestamp::now_seconds()/MINUTE_CONVERSION_FACTOR;
        let min_voting_time = dao.min_voting_time;
        if(debating_time < min_voting_time){
            deadline = deadline + min_voting_time;
        } else {
            deadline = deadline + debating_time;
        };

        let approval_threshold = dao.n_members * dao.min_voting_percentage /100;
        let id = dao.sku;
        
        let voted = vector::empty<address>();
        vector::push_back(&mut voted, member_address);
        //Create Proposal and add to member + add ID and member address to DAO 
        add_proposal_to_member<CoinType>(
            member_address,
            id,
            Proposal<CoinType>{
                id: id,
                recipient: recipient,
                investment: investment,
                deadline: deadline,
                active: true,
                approved: false,
                approval_threshold: approval_threshold,
                deposit: proposal_deposit,
                n_yes: 1,
                n_no: 0,
                voted: voted,
            }
        );

        table_with_length::add(&mut dao.proposal_addresses, id, member_address);
        dao.sku = id + 1;

        let dao_member = borrow_global_mut<DAO_member<CoinType>>(member_address);
        dao_member.n_total_proposals = dao_member.n_total_proposals + 1;
        event::emit_event<ProposalAddedEvent>(
            &mut dao_member.proposal_added_event,
            ProposalAddedEvent { 
                proposal_id: id, 
                recipient: recipient,
                investment: investment,
            },
        );
    }

    public entry fun cast_vote<CoinType>(member: &signer, dao_address: address, proposal_id: u64, vote: bool) acquires DAO, DAO_member {
        only_member<CoinType>(member);
        only_if_dao<CoinType>(dao_address);
        let member_address = signer::address_of(member);
        let dao = borrow_global_mut<DAO<CoinType>>(dao_address);
        assert!(table_with_length::contains(& dao.proposal_addresses, proposal_id), ENO_PROPOSAL_WITH_ID);
        let proposal_address = table_with_length::borrow(&mut dao.proposal_addresses, proposal_id);
        let proposals_at_address = &mut borrow_global_mut<DAO_member<CoinType>>(*proposal_address).active_proposals;
        let proposal = table_with_length::borrow_mut(proposals_at_address, proposal_id);

        let now = timestamp::now_seconds()/MINUTE_CONVERSION_FACTOR;
        assert!(now < proposal.deadline, EPROPOSAL_DEADLINE_PASSED);
        assert!(proposal.active, EPROPOSAL_EXPIRED);

        assert!(!vector::contains(&mut proposal.voted, & member_address), EALREADY_VOTED);
        
        if(vote){
            proposal.n_yes = proposal.n_yes + 1;
        } else {
            proposal.n_no = proposal.n_no + 1;
        };

        vector::push_back(&mut proposal.voted, member_address);

        //Future feature: Keep track of active votes
        //vector::push_back(&mut dao_member.active_votes, proposal_id);

        if(proposal.n_yes >= proposal.approval_threshold){
            proposal.approved = true;
        };

        let dao_member = borrow_global_mut<DAO_member<CoinType>>(member_address);
        event::emit_event<VotedEvent>(
            &mut dao_member.voted_event,
            VotedEvent { 
                proposal_id: proposal_id, 
                vote: vote,
            },
        );
    }

    public entry fun execute_proposal<CoinType>(owner: &signer, proposal_id: u64) acquires DAO, DAO_member {
        only_owner<CoinType>(owner);
        let owner_address = signer::address_of(owner);
        let dao = borrow_global_mut<DAO<CoinType>>(owner_address);
        assert!(table_with_length::contains(& dao.proposal_addresses, proposal_id), ENO_PROPOSAL_WITH_ID);
        let proposal_address = table_with_length::remove(&mut dao.proposal_addresses, proposal_id);
        let proposals_at_address = &mut borrow_global_mut<DAO_member<CoinType>>(proposal_address).active_proposals;
        let Proposal<CoinType>{
                id: _,
                recipient: recipient,
                investment: investment,
                deadline: _,
                active: active,
                approved: approved,
                approval_threshold: _,
                deposit: deposit,
                n_yes: _,
                n_no: _,
                voted: _,
            } = table_with_length::remove(proposals_at_address, proposal_id);

        //Check if proposal has been approved (received the required number of votes)
        assert!(approved, EPROPOSAL_NOT_APPROVED);

        //Check if proposal is still active
        assert!(active, EPROPOSAL_EXPIRED);

        //Check if the recipient is still whitelisted
        let whitelisted = & dao.whitelisted_recipients;
        assert!(vector::contains(whitelisted, & recipient), ERECIPIENT_NOT_WHITELISTED);

        //Check if deadline has been reached
        //let now = timestamp::now_seconds()/MINUTE_CONVERSION_FACTOR;
        //assert!(now >= proposal.deadline, EPROPOSAL_DEADLINE_NOT_REACHED);

        //Check if the DAO has enough funds to currently fund the investment proposal
        assert!(coin::value(& dao.funds) >= investment, ENOT_ENOUGH_FUNDS_IN_DAO);

        //Transfer funds to recipient
        coin::deposit(recipient, coin::extract(&mut dao.funds, investment));

        //Return deposit + deactivate proposal
        coin::deposit(proposal_address, deposit);

        event::emit_event<ExecutedEvent>(
            &mut dao.executed_event,
            ExecutedEvent { 
                proposal_id: proposal_id, 
                amount_invested: investment,
            },
        );

        //Future feature: Remove proposal id from active votes vector of all the dao_members that voted
        //remove_proposal_id<CoinType>(proposal.voted, proposal_id);
    }

    // Non approved proposals can be closed by the owner. Even if the deadline has not yet reached
    public entry fun close_proposal<CoinType>(owner: &signer, proposal_id: u64) acquires DAO, DAO_member {
        only_owner<CoinType>(owner);
        let owner_address = signer::address_of(owner);
        let dao = borrow_global_mut<DAO<CoinType>>(owner_address);
        assert!(table_with_length::contains(& dao.proposal_addresses, proposal_id), ENO_PROPOSAL_WITH_ID);
        let proposal_address = table_with_length::remove(&mut dao.proposal_addresses, proposal_id);
        let proposals_at_address = &mut borrow_global_mut<DAO_member<CoinType>>(proposal_address).active_proposals;
        let Proposal<CoinType>{
                id: _,
                recipient: _,
                investment: _,
                deadline: _,
                active: _,
                approved: approved,
                approval_threshold: _,
                deposit: deposit,
                n_yes: _,
                n_no: _,
                voted: _,
            } = table_with_length::remove(proposals_at_address, proposal_id);

        //Check if proposal has been approved (received the required number of votes)
        assert!(!approved, EPROPOSAL_IS_APPROVED);

        //Return deposit
        coin::deposit(proposal_address, deposit);

        //Future feature
        //remove_proposal_id<CoinType>(proposal.voted, proposal_id);

        event::emit_event<ClosedEvent>(
            &mut dao.closed_event,
            ClosedEvent { proposal_id: proposal_id },
        );
    }

//Future feature: keep track of active votes
    // fun remove_proposal_id<CoinType>(voted_vector: vector<address>, proposal_id: u64) acquires DAO_member {
    //     while (!vector::is_empty<address>(&mut voted_vector)){
    //         let member_address = vector::pop_back<address>(&mut voted_vector);
    //         let active_votes = &mut borrow_global_mut<DAO_member<CoinType>>(member_address).active_votes;
    //         let (_,index) = vector::index_of(active_votes, & proposal_id);
    //         vector::remove(active_votes, index);
    //     }
    // }

//TESTS
    //INIT DAO TEST
    #[test_only]
    public entry fun init_test_dao<CoinType>(owner: &signer) {
        let min_investment = 10000000;
        let min_voting_percentage = 50;
        let min_voting_time = 5;
        let proposal_deposit = 100000;
        initialise_DAO<CoinType>(owner, min_investment, min_voting_percentage, min_voting_time, proposal_deposit);
    }

    #[test_only]
    public entry fun init_test_proposal<CoinType>(member: &signer, dao_address: address, recipient_address: address): u64 acquires DAO, DAO_member{
        let recipient = recipient_address;
        let investment = 10000000;
        let debating_time = 1;
        let id = borrow_global<DAO<CoinType>>(dao_address).sku;
        new_proposal<CoinType>(member, dao_address, recipient, investment, debating_time);
        id
    }

    //INIT TEST FUNCTION
    #[test_only]
    public entry fun is_owner_test<CoinType>(owner: &signer): bool {
        exists<DAO<CoinType>>(signer::address_of(owner))
    }
    //ACCESS CONTROL TEST FUNCTIONS
    #[test_only]
    public entry fun is_member_test<CoinType>(member: &signer): bool {
        exists<DAO_member<CoinType>>(signer::address_of(member))
    }

    #[test_only]
    public entry fun test_has_proposal<CoinType>(member: &signer): bool acquires DAO_member {
        only_member<CoinType>(member);
        let member_address = signer::address_of(member);
        !table_with_length::empty(& borrow_global<DAO_member<CoinType>>(member_address).active_proposals)
    }
}