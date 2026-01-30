#[starknet::interface]
pub trait ISomeContract<TContractState> {
    fn divide(self: @TContractState, n: usize, d: usize) -> usize;
}

#[starknet::contract]
pub mod SomeContract {
    // import the required functions from the starknet core library
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        balance: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.owner.write(get_caller_address());
    }

    #[generate_trait]
    impl Internal of InternalTrait {
        fn only_owner(self: @ContractState) {
            let caller = get_caller_address();
            let stored_owner = self.owner.read();

            // ENSURES THE CALLER IS THE OWNER OR REVERT
            assert(caller == stored_owner, 'Not owner');
        }
        fn not_zero(self: @ContractState, n: usize, d: usize) {
            assert!(d != 0, "{} is not divisible by {}", n, d);
        }
    }

    // divide FUNCTION
    #[external(v0)]
    pub fn divide(ref self: ContractState, n: usize, d: usize) -> usize {
        self.only_owner();
        self.not_zero(n, d);
        // callMe logic
        n / d
    }
}
