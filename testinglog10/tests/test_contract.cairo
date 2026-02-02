use snforge_std::{
    ContractClassTrait, DeclareResultTrait, Event, EventSpyAssertionsTrait, EventSpyTrait,
    IsEmitted, declare, spy_events,
};
use starknet::{ContractAddress, get_block_timestamp};
use testinglog10::{
    IUserManagerDispatcher, IUserManagerDispatcherTrait, UserManager, UserRegistered,
};

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_registration_event_emission() {
    // Deploy the UserManager contract
    let contract_address = deploy_contract("UserManager");

    // Create a dispatcher to interact with the deployed contract
    let dispatcher = IUserManagerDispatcher { contract_address };

    // Start spying on events before the function call
    let mut spy = spy_events();

    // Register a user - this should emit a UserRegistered event
    dispatcher.register_user("serah");

    // Verify that the expected event was emitted with correct data
    spy
        .assert_emitted(
            @array![
                (
                    contract_address, // Event should come from our contract
                    UserManager::Event::UserRegistered(
                        UserRegistered {
                            user_id: 1, // First user gets ID 1
                            username: "serah", // Username matches what we passed
                            timestamp: get_block_timestamp() // Timestamp should be current block time
                        },
                    ),
                ),
            ],
        );
}

#[test]
fn test_event_structure() {
    // Deploy the UserManager contract
    let contract_address = deploy_contract("UserManager");

    // Create a dispatcher to interact with the deployed contract
    let dispatcher = IUserManagerDispatcher { contract_address };

    // Start event spy to capture all emitted events
    let mut spy = spy_events();

    // Register a user which should emit a UserRegistered event
    dispatcher.register_user("serah");

    // Retrieve all captured events for analysis
    let events = spy.get_events();
    assert(events.events.len() == 1, 'There should be one event');

    // Create the expected event structure for comparison
    let expected_event = UserManager::Event::UserRegistered(
        UserRegistered { user_id: 1, username: "serah", timestamp: get_block_timestamp() },
    );

    // Check if the expected event was actually emitted
    assert!(events.is_emitted(contract_address, @expected_event));

    // Create array of expected events for exact comparison
    let expected_events: Array<(ContractAddress, Event)> = array![
        (contract_address, expected_event.into()),
    ];
    assert!(events.events == expected_events);

    // Extract and examine the raw event data
    let (from, event) = events.events.at(0);
    assert(from == @contract_address, 'Emitted from wrong address');

    // Verify event keys structure (event selector + indexed fields)
    assert(event.keys.len() == 2, 'There should be two keys');
    assert(event.keys.at(0) == @selector!("UserRegistered"), 'Wrong event name');
}
