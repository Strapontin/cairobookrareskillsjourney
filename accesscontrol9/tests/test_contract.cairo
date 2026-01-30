use accesscontrol9::{
    ISomeContractDispatcher, ISomeContractDispatcherTrait, ISomeContractSafeDispatcher,
    ISomeContractSafeDispatcherTrait,
};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_division() {
    let contract_address = deploy_contract("SomeContract");

    let dispatcher = ISomeContractDispatcher { contract_address };

    let mut n: usize = 1;
    let mut d: usize = 1;
    let result = dispatcher.divide(n, d);
    println!("Result = {}", result);
    // assert(balance_before == 0, 'Invalid balance');

    d = 0;
    let result = dispatcher.divide(n, d);
    println!("Result = {}", result);
    // dispatcher.increase_balance(42);

    // let balance_after = dispatcher.get_balance();
// assert(balance_after == 42, 'Invalid balance');
}
