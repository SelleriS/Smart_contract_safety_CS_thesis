module testing2::flagging_donor2{
    use std::signer;

    const EDONOR_FLAGGED: u64 = 101;

    struct BigDonorFlag has key {
        flagged: bool,
    }

    public fun addFlag(account: &signer, amount: u64):bool acquires BigDonorFlag {
        let addr = signer::address_of(account);
        if(!exists<BigDonorFlag>(addr)){
            move_to(account, BigDonorFlag {flagged: (amount >= 30000000u64)});
        } else {
            let flag = borrow_global_mut<BigDonorFlag>(addr);
            flag.flagged = (amount >= 30000000u64);
        }; 
        (amount >= 30000000u64)
    }

    // Used for testing purposes
    public entry fun isFlagged(addr: address) {
        assert!(!exists<BigDonorFlag>(addr), EDONOR_FLAGGED);
    }

    public entry fun unFlag(addr:address) acquires BigDonorFlag {
        if(exists<BigDonorFlag>(addr)){
            let BigDonorFlag{flagged: _flagged} = move_from<BigDonorFlag>(addr);
        }
    }

    #[test_only]
    public fun addFlag_test(account: &signer, amount: u64):bool acquires BigDonorFlag {
        let addr = signer::address_of(account);
        isFlagged(addr); // prevents from donating twice. Used to see if errors are pushed upwards
        if(!exists<BigDonorFlag>(addr)){
            move_to(account, BigDonorFlag {flagged: (amount >= 30000000u64)});
        } else {
            let flag = borrow_global_mut<BigDonorFlag>(addr);
            flag.flagged = (amount >= 30000000u64);
        }; 
        (amount >= 30000000u64)
    }
}