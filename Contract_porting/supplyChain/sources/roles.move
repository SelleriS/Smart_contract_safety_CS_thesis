module testing::roles{
    friend testing::supplychain;
    use std::signer;

    const EACCOUNT_ALREADY_APPLIED: u64 = 100;
    const EACCOUNT_DID_NOT_APPLY: u64 = 101;
    const EACCOUNT_ALREADY_APPROVED_FOR_THIS_ROLE: u64 = 102;
    const EACCOUNT_NOT_APPROVED_FOR_THIS_ROLE: u64 = 103;

    struct FarmerRole {}
    struct DistributorRole {}
    struct RetailerRole {}
    struct ConsumerRole {}
    struct Role<phantom RoleType> has key {
        approved: bool
    }

    // Roles:
    // An accoungt can register for a certain role. The registration must still be approved by the owner
    public(friend) fun apply_for_role<RoleType>(account: &signer) {
        let account_addr = signer::address_of(account);
        assert!(!exists<Role<RoleType>>(account_addr), EACCOUNT_ALREADY_APPLIED);
        move_to<Role<RoleType>>(account, Role {approved: false});
    }

    // Returns `true` if `account_addr` is registered to receive `RoleType`.
    fun is_account_registered_for_role<RoleType>(account_addr: address): bool {
        exists<Role<RoleType>>(account_addr)
    }

    public(friend) fun is_account_approved_for_role<RoleType>(account_addr: address): bool acquires Role {
        assert!(is_account_registered_for_role<RoleType>(account_addr), EACCOUNT_DID_NOT_APPLY);
        borrow_global<Role<RoleType>>(account_addr).approved
    }

    //Owner can approve a registered account for the roletype that they registered for
    //The owner check has to happen in the supplychain module
    public(friend) fun approve_account<RoleType>(account_addr: address) acquires Role {
        assert!(!is_account_approved_for_role<RoleType>(account_addr), EACCOUNT_ALREADY_APPROVED_FOR_THIS_ROLE);
        let approved = &mut borrow_global_mut<Role<RoleType>>(account_addr).approved;
        *approved = true;
    }

    //Remove Role (approved or not) from the account by using pattern matching
    public(friend) fun remove_account<RoleType>(account_addr: address) acquires Role {
        assert!(is_account_registered_for_role<RoleType>(account_addr), EACCOUNT_DID_NOT_APPLY);
        let Role<RoleType>{approved: _approved} = move_from<Role<RoleType>>(account_addr);
    }

//TEST FUNCTIONS
    #[test_only]
    public entry fun approve_account_test<RoleType>(account_addr: address) acquires Role {
        assert!(!is_account_approved_for_role<RoleType>(account_addr), EACCOUNT_ALREADY_APPROVED_FOR_THIS_ROLE);
        let approved = &mut borrow_global_mut<Role<RoleType>>(account_addr).approved;
        *approved = true;
    }

}