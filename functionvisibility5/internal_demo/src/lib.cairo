/// Interface representing `HelloContract`.
/// This interface allows modification and retrieval of the contract balance.
#[starknet::interface]
pub trait IHelloStarknet<TContractState> {
    /// Increase contract balance.
    fn increase_balance(ref self: TContractState, amount: felt252);
    /// Retrieve contract balance.
    fn get_balance(self: @TContractState) -> felt252;

    // Retrieve the 2x balance
    fn extern_wrap_get_balance_2x(self: @TContractState) -> felt252;
}

/// Simple contract for managing balance.
#[starknet::contract]
mod HelloStarknet {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use crate::IHelloStarknet;

    #[storage]
    struct Storage {
        balance: felt252,
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            self.balance.write(self.balance.read() + amount);
        }

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }

        fn extern_wrap_get_balance_2x(self: @ContractState) -> felt252 {
            self.get_balance_2x()
        }
    }

    #[generate_trait] // Compiler generates the trait automatically
    impl InternalFunction_ArbitraryNameeeeeee of IInternal {
        // NEWLY ADDED FUNCTION
        fn get_balance_2x(self: @ContractState) -> felt252 {
            self.balance.read() * 2
        }
    }
}
