module testing2::flagging_donor{
    use std::signer;

    const EDONOR_FLAGGED: u64 = 101;
    const EDONOR_NOT_FLAGGED: u64 = 102;

    struct BigDonorFlag has key {
        flagged: bool,
    }

    public fun addFlag(account: &signer, amount: u64) acquires BigDonorFlag {
        let addr = signer::address_of(account);
        
        if(amount >= 30000000u64){
            if(!exists<BigDonorFlag>(addr)){
                move_to(account, BigDonorFlag {flagged: true});
            } else {
                let flag = borrow_global_mut<BigDonorFlag>(addr);
                flag.flagged = true;
            } 
        }
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
}