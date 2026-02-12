// SAME TRAIT SCARB CREATES BY DEFAULT

#[starknet::interface]
pub trait IHelloStarknet<TContractState> {
    /// Increase contract balance.
    fn increase_balance(ref self: TContractState, amount: felt252);
    /// Retrieve contract balance.
    fn get_balance(self: @TContractState) -> felt252;
}

// COMPONENT IS NEW

#[starknet::component]
pub mod CounterComponent {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        x: felt252,
    }

    #[event]
    #[derive(Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {}

    #[embeddable_as(CounterImplMixin)]
    impl CounterImpl<
        TContractState, +HasComponent<TContractState>,
    > of super::IHelloStarknet<ComponentState<TContractState>> {
        fn get_balance(self: @ComponentState<TContractState>) -> felt252 {
            self.x.read()
        }

        fn increase_balance(ref self: ComponentState<TContractState>, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            self.x.write(self.x.read() + amount);
        }
    }
}

// THIS CONTRACT HAS NO FUNCTIONALITY, IT ONLY USES THE COMPONENT

#[starknet::contract]
mod HelloStarknet {
    use super::CounterComponent;

    component!(path: CounterComponent, storage: counter, event: CounterEvent);

    #[abi(embed_v0)]
    impl CounterImpl = CounterComponent::CounterImplMixin<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        counter: CounterComponent::Storage,
    }

    #[event]
    #[derive(Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        #[flat]
        CounterEvent: CounterComponent::Event,
    }
}
