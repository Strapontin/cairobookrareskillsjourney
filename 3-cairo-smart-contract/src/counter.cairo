// Define a trait with two functions
#[starknet::interface]
pub trait ICounter<TContractState> {
    // Function that can read and modify the contract's state
    fn increase_counter(ref self: TContractState, amount: felt252);

    // Function that can only read from the contract's state
    fn get_counter(self: @TContractState) -> felt252;
}

#[starknet::contract]
mod Counter {
    // Storage traits
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    // The struct must be named Storage to be used as a contract's storage
    #[storage]
    struct Storage {
        counter: felt252,
    }

    // Implement the functions within the `ICounter` trait
    #[abi(embed_v0)]
    impl CounterImpl of super::ICounter<ContractState> {
        fn increase_counter(ref self: ContractState, amount: felt252) {
            self.counter.write(self.counter.read() + amount);
        }

        fn get_counter(self: @ContractState) -> felt252 {
            self.counter.read()
        }
    }

    #[external(v0)]
    fn increase_counter_by_five(ref self: ContractState) {
        self.counter.write(self.counter.read() + get_five());
    }

    fn get_five() -> felt252 {
        5
    }
}
