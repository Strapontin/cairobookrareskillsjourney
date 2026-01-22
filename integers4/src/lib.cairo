#[starknet::interface]
pub trait IHelloStarknet<TContractState> {
    fn underflow(ref self: TContractState, x: u256, y: u256) -> u256;
    fn math_demo(self: @TContractState, x: felt252, y: felt252) -> felt252;
}

#[starknet::contract]
mod HelloStarknet {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
        fn underflow(ref self: ContractState, x: u256, y: u256) -> u256 {
            x - y
        }
        fn math_demo(self: @ContractState, x: felt252, y: felt252) -> felt252 {
            x - y
        }
    }
}

