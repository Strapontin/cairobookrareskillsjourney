use cheatcodes11::{
    IHelloStarknetDispatcher, IHelloStarknetDispatcherTrait, IHelloStarknetSafeDispatcher,
    IHelloStarknetSafeDispatcherTrait,
};
// Import necessary cfor cheatcodes
use snforge_std::{CheatSpan, ContractClassTrait, DeclareResultTrait, cheat_caller_address, declare};
use snforge_std::{
    start_cheat_caller_address, start_cheat_caller_address_global, stop_cheat_caller_address,
    stop_cheat_caller_address_global,
};
use starknet::ContractAddress;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_increase_balance() {
    let contract_address = deploy_contract("HelloStarknet");

    let dispatcher = IHelloStarknetDispatcher { contract_address };

    let balance_before = dispatcher.get_balance();
    assert(balance_before == 0, 'Invalid balance');

    dispatcher.increase_balance(42);

    let balance_after = dispatcher.get_balance();
    assert(balance_after == 42, 'Invalid balance');

    //* Start cheatcodes list *//
    let OWNER: ContractAddress = 'OWNER'.try_into().unwrap();

    // prank an address for x calls to a specific contract/account
    cheat_caller_address(contract_address, OWNER, CheatSpan::TargetCalls(1));

    // prank an address for all next calls to a specific contract/account
    cheat_caller_address(contract_address, OWNER, CheatSpan::Indefinite);

    // Starts pranking an address for next calls to a specific contract/account
    start_cheat_caller_address(contract_address, OWNER);

    // start pranking and address for all next calls
    start_cheat_caller_address_global(OWNER);

    // Stops the prank toward a specific contract/account
    stop_cheat_caller_address(contract_address);

    // Like vm.stopPrank() in solidity
    stop_cheat_caller_address_global();
}

// Example of use of SAFE DISPATCHER (does not panic when call panics)
const USER: ContractAddress = 'USER'.try_into().unwrap();

#[test]
#[feature("safe_dispatcher")]
fn test_non_owner_error_with_safe_dispatcher() {
    // Deploy the HelloStarknet contract with OWNER as the owner
    let contract_address = deploy_contract("HelloStarknet", OWNER);

    // Use the safe dispatcher variant to handle errors gracefully
    let safe_dispatcher = IHelloStarknetSafeDispatcher { contract_address };

    // Impersonate USER who is NOT the owner
    start_cheat_caller_address(contract_address, USER);

    // Call increase_balance - this will fail but return a Result instead of panicking
    match safe_dispatcher.increase_balance(100) {
        // If the call succeeds, the test should fail because non-owners shouldn't have access
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        // If the call fails (expected), confirm we get the correct error message
        Result::Err(panic_data) => {
            // Check that the first element of panic_data contains our expected error message
            assert(*panic_data.at(0) == 'Only owner', 'Wrong error message');
        },
    }

    // stop the caller impersonation
    stop_cheat_caller_address(contract_address);
}

// Writes in the storage
#[test]
fn test_store_balance_directly() {
    let contract_address = deploy_contract("HelloStarknet", OWNER);
    let dispatcher = IHelloStarknetDispatcher { contract_address };

    //calculate the storage address where the "balance" variable is stored
    let balance_storage_addr = map_entry_address(
        map_selector: selector!("balance"), keys: array![].span(),
    );

    // value to write directly to storage
    let new_balance: u256 = 5000;

    // Serialize u256 into low and high parts (u256 = {low: u128, high: u128})
    // In Cairo, u256 values are serialized as 2 felt252 values - one for lower 128 bits, one for
    // upper 128 bits
    let serialized_value = array![new_balance.low.into(), new_balance.high.into()];

    // Check balance before direct storage write
    let balance_before = dispatcher.get_balance();
    assert(balance_before == 0, 'Initial balance should be 0');

    // write directly to storage
    store(contract_address, balance_storage_addr, serialized_value.span());

    assert(dispatcher.get_balance() == 5000, 'Direct storage write failed');
}

// Reads from the storage (without using the contract's functions)
#[test]
fn test_load_balance_directly() {
    let contract_address = deploy_contract("HelloStarknet", OWNER);

    // Calculate the storage address where the "balance" variable is stored
    let balance_storage_addr = selector!("balance");

    // Value to write directly to storage
    let new_balance: u256 = 5000;

    // Serialize u256 into low and high parts (u256 = {low: u128, high: u128})
    // In Cairo, u256 values are serialized as 2 felt252 values - one for lower 128 bits, one for
    // upper 128 bits
    let serialized_value = array![new_balance.low.into(), new_balance.high.into()];

    // Write directly to storage
    store(contract_address, balance_storage_addr, serialized_value.span());

    // Read the raw storage data from the balance storage slot
    let stored_data = load(contract_address, balance_storage_addr, 2);

    // Extract the low and high parts from the storage data array
    let stored_balance_low = *stored_data.at(0);
    let stored_balance_high = *stored_data.at(1);

    // Reconstruct the u256 from its low and high components
    let stored_balance: u256 = u256 {
        low: stored_balance_low.try_into().unwrap(), high: stored_balance_high.try_into().unwrap(),
    };

    // Confirm that the directly read storage value matches our expected balance
    assert(stored_balance == 5000, 'Direct storage read failed');
}
