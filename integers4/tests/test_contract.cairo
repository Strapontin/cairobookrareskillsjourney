use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use integers4::{ IHelloStarknetDispatcher, IHelloStarknetDispatcherTrait};
use starknet::ContractAddress;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
#[should_panic]
fn test_flow_protection() {
    let contract_address = deploy_contract("HelloStarknet");

    let dispatcher = IHelloStarknetDispatcher { contract_address };

    dispatcher.underflow(0, 1);
}

#[test]
fn test_math_demo() {
    let contract_address = deploy_contract("HelloStarknet");
    let dispatcher = IHelloStarknetDispatcher { contract_address };
    let result = dispatcher.math_demo(0, 1); // 0 - 1
    println!("result: {}", result);
}