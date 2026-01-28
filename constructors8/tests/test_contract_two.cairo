use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;

// Change return type to a tuple so we can capture the constructor’s return value.
fn deploy_contract(name: ByteArray) -> (ContractAddress, felt252) {
    let contract = declare(name).unwrap().contract_class();

    // Capture both the contract address and the constructor’s return values (as a Span<felt252>).
    let (contract_address, ret_vals) = contract.deploy(@ArrayTrait::new()).unwrap();

    // Return the address plus the first element in ret_vals (we expect only one value).
    (contract_address, *ret_vals.at(0))
}

#[test]
fn test_increase_balance() {
    let (_, ret_val) = deploy_contract("HelloStarknet");

        // Verify that the constructor actually returned 33 as expected.
    assert(ret_val == 33, 'Invalid return value.');
}
