//NEWLY ADDED BELOW//
use erc20starknet12::{
    IERC20Dispatcher, IERC20DispatcherTrait, IERC20SafeDispatcher, IERC20SafeDispatcherTrait,
};
use snforge_std::{
    CheatSpan, ContractClassTrait, DeclareResultTrait, cheat_caller_address, declare,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::{ContractAddress, SyscallResultTrait};

// Helper function to deploy the ERC20 contract with a specified owner
fn deploy_contract(name: ByteArray, owner: ContractAddress) -> ContractAddress {
    let contract = declare(name).unwrap_syscall().contract_class(); // Declare the contract class
    let constructor_args = array![owner.into()]; // Pass owner to constructor
    let (contract_address, _) = contract
        .deploy(@constructor_args)
        .unwrap_syscall(); // Deploy the contract and return its address
    contract_address
}


const OWNER: ContractAddress = 'OWNER'.try_into().unwrap();
const TOKEN_RECIPIENT: ContractAddress = 'RECIPIENT'.try_into().unwrap();

// NEWLY ADDED BELOW
#[test]
fn test_token_constructor() {
    // Deploy the ERC20 contract with OWNER as the owner
    let contract_address = deploy_contract("ERC20", OWNER);

    // Create a dispatcher to interact with the deployed contract
    let erc20_token = IERC20Dispatcher { contract_address };

    // Retrieve token metadata from the contract
    let token_name = erc20_token.name();
    let token_symbol = erc20_token.symbol();
    let token_decimal = erc20_token.decimals();

    // Verify that the constructor set the correct values
    assert(token_name == "Rare Token", 'Wrong token name');
    assert(token_symbol == "RST", 'Wrong token symbol');
    assert(token_decimal == 18, 'Wrong token decimal');
}

#[test]
fn test_total_supply() {
    // Deploy the contract
    let contract_address = deploy_contract("ERC20", OWNER);

    // Create dispatcher to interact with the contract
    let erc20_token = IERC20Dispatcher { contract_address };

    // Calculate mint amount: 1000 tokens adjusted for decimals
    let token_decimal = erc20_token.decimals();
    let mint_amount = 1000 * token_decimal.into();

    // Impersonate the owner for the next function call (mint)
    cheat_caller_address(contract_address, OWNER, CheatSpan::TargetCalls(1));
    erc20_token.mint(TOKEN_RECIPIENT, mint_amount);

    // Get the total supply
    let supply = erc20_token.total_supply();

    // Verify total supply matches the minted amount
    assert(supply == mint_amount, 'Incorrect Supply');
}

#[test]
fn test_transfer() {
    // Deploy the contract
    let contract_address = deploy_contract("ERC20", OWNER);
    let erc20_token = IERC20Dispatcher { contract_address };

    // Get token decimals for proper amount calculation
    let token_decimal = erc20_token.decimals();

    // Define amounts: 10,000 tokens to mint, 5,000 to transfer
    let amount_to_mint: u256 = 10000 * token_decimal.into();
    let amount_to_transfer: u256 = 5000 * token_decimal.into();

    // Start impersonating the owner for multiple calls
    start_cheat_caller_address(contract_address, OWNER);

    // Mint tokens to the owner
    erc20_token.mint(OWNER, amount_to_mint);

    // Verify the mint was successful
    assert(erc20_token.balance_of(OWNER) == amount_to_mint, 'Incorrect minted amount');

    // Track recipient's balance before transfer
    let receiver_previous_balance = erc20_token.balance_of(TOKEN_RECIPIENT);

    // Transfer tokens from owner to recipient
    erc20_token.transfer(TOKEN_RECIPIENT, amount_to_transfer);

    // Stop impersonating the owner
    stop_cheat_caller_address(contract_address);

    // Verify sender's balance decreased correctly
    assert(erc20_token.balance_of(OWNER) < amount_to_mint, 'Sender balance not reduced');
    assert(
        erc20_token.balance_of(OWNER) == amount_to_mint - amount_to_transfer,
        'Wrong sender balance',
    );

    // Verify recipient's balance increased correctly
    assert(
        erc20_token.balance_of(TOKEN_RECIPIENT) > receiver_previous_balance,
        'Recipient balance unchanged',
    );
    assert(erc20_token.balance_of(TOKEN_RECIPIENT) == amount_to_transfer, 'Wrong recipient amount');
}


#[test]
#[should_panic(expected: ('Insufficient amount',))]
fn test_transfer_insufficient_balance() {
    // Deploy the contract
    let contract_address = deploy_contract("ERC20", OWNER);
    let erc20_token = IERC20Dispatcher { contract_address };

    let token_decimal = erc20_token.decimals();

    // Define amounts: only 5,000 tokens minted, but attempting to transfer 10,000
    let mint_amount: u256 = 5000 * token_decimal.into();
    let transfer_amount: u256 = 10000 * token_decimal.into();

    // Start impersonating the owner
    start_cheat_caller_address(contract_address, OWNER);

    // Mint only 5,000 tokens to the owner
    erc20_token.mint(OWNER, mint_amount);

    // Verify the mint was successful
    assert(erc20_token.balance_of(OWNER) == mint_amount, 'Mint failed');

    // Attempt to transfer more than balance (10,000 tokens when only 5,000 exist)
    // This should panic with 'Insufficient amount'
    erc20_token.transfer(TOKEN_RECIPIENT, transfer_amount);

    // Stop impersonating the owner
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_approve() {
    let contract_address = deploy_contract("ERC20", OWNER);
    let erc20_token = IERC20Dispatcher { contract_address };

    let token_decimal = erc20_token.decimals();
    let mint_amount: u256 = 10000 * token_decimal.into();
    let approval_amount: u256 = 5000 * token_decimal.into();

    // Start impersonating the owner
    start_cheat_caller_address(contract_address, OWNER);

    // Mint tokens to the owner first
    erc20_token.mint(OWNER, mint_amount);

    // Verify mint succeeded
    assert(erc20_token.balance_of(OWNER) == mint_amount, 'Mint failed');

    // Owner approves the recipient to spend tokens
    erc20_token.approve(TOKEN_RECIPIENT, approval_amount);

    // Stop impersonating the owner
    stop_cheat_caller_address(contract_address);

    // Verify the allowance was set
    assert(erc20_token.allowance(OWNER, TOKEN_RECIPIENT) > 0, 'Incorrect allowance');
    assert(
        erc20_token.allowance(OWNER, TOKEN_RECIPIENT) == approval_amount, 'Wrong allowance amount',
    );
}

#[test]
fn test_transfer_from() {
    // Deploy the contract
    let contract_address = deploy_contract("ERC20", OWNER);
    let erc20_token = IERC20Dispatcher { contract_address };

    let token_decimal = erc20_token.decimals();

    // Define amounts: 10,000 tokens to mint, 5,000 to approve and transfer
    let mint_amount: u256 = 10000 * token_decimal.into();
    let transfer_amount: u256 = 5000 * token_decimal.into();

    // Start impersonating the owner
    start_cheat_caller_address(contract_address, OWNER);

    // Mint tokens to the owner
    erc20_token.mint(OWNER, mint_amount);

    // Verify mint succeeded
    assert(erc20_token.balance_of(OWNER) == mint_amount, 'Mint failed');

    let spender: ContractAddress = 'SPENDER'.try_into().unwrap();

    // Owner approves SPENDER to spend tokens on their behalf
    erc20_token.approve(spender, transfer_amount);

    // Stop impersonating owner
    stop_cheat_caller_address(contract_address);

    // Verify the allowance was set correctly
    assert(erc20_token.allowance(OWNER, spender) == transfer_amount, 'Approval failed');

    // Track balances before transfer
    let owner_balance_before = erc20_token.balance_of(OWNER);
    let recipient_balance_before = erc20_token.balance_of(TOKEN_RECIPIENT);
    let allowance_before = erc20_token.allowance(OWNER, spender);

    // Now impersonate the SPENDER to call transfer_from
    cheat_caller_address(contract_address, spender, CheatSpan::TargetCalls(1));
    erc20_token.transfer_from(OWNER, TOKEN_RECIPIENT, transfer_amount);

    // Verify owner's balance decreased
    assert(
        erc20_token.balance_of(OWNER) == owner_balance_before - transfer_amount,
        'Owner balance wrong',
    );

    // Verify recipient's balance increased
    assert(
        erc20_token.balance_of(TOKEN_RECIPIENT) == recipient_balance_before + transfer_amount,
        'Recipient balance wrong',
    );

    // Verify allowance decreased
    assert(
        erc20_token.allowance(OWNER, spender) == allowance_before - transfer_amount,
        'Allowance not reduced',
    );
}

#[test]
#[should_panic(expected: ('u256_sub Overflow',))]
fn test_transfer_from_insufficient_allowance() {
    // Deploy the contract
    let contract_address = deploy_contract("ERC20", OWNER);
    let erc20_token = IERC20Dispatcher { contract_address };

    let token_decimal = erc20_token.decimals();

    // Define amounts: 10,000 tokens to mint, 5,000 to approve
    let mint_amount: u256 = 10000 * token_decimal.into();
    let approval_amount: u256 = 5000 * token_decimal.into();

    // Start impersonating the owner
    start_cheat_caller_address(contract_address, OWNER);

    // Mint tokens to the owner
    erc20_token.mint(OWNER, mint_amount);

    let spender: ContractAddress = 'SPENDER'.try_into().unwrap();

    // Owner approves SPENDER to spend 5,000 tokens
    erc20_token.approve(spender, approval_amount);

    // Stop impersonating owner
    stop_cheat_caller_address(contract_address);

    // Attempt to transfer more than approved (6,000 instead of 5,000)
    // This should panic with 'amount exceeds allowance'
    cheat_caller_address(contract_address, spender, CheatSpan::TargetCalls(1));
    erc20_token.transfer_from(OWNER, TOKEN_RECIPIENT, 6000 * token_decimal.into());
}


#[test]
#[should_panic(expected: ('u256_sub Overflow',))]
fn test_transfer_from_insufficient_balance() {
    // Deploy the contract
    let contract_address = deploy_contract("ERC20", OWNER);
    let erc20_token = IERC20Dispatcher { contract_address };

    let token_decimal = erc20_token.decimals();

    // Define amounts: only 1,000 tokens minted, but 2,000 approved and attempted
    let mint_amount: u256 = 1000 * token_decimal.into();
    let approval_amount: u256 = 2000 * token_decimal.into();
    let transfer_amount: u256 = 2000 * token_decimal.into();

    // Start impersonating the owner
    start_cheat_caller_address(contract_address, OWNER);

    // Mint only 1,000 tokens to the owner
    erc20_token.mint(OWNER, mint_amount);

    let spender: ContractAddress = 'SPENDER'.try_into().unwrap();

    // Owner approves SPENDER to spend 2,000 tokens (more than balance)
    erc20_token.approve(spender, approval_amount);

    // Stop impersonating owner
    stop_cheat_caller_address(contract_address);

    // Spender has sufficient allowance but owner doesn't have enough balance
    // This should panic with 'amount exceeds balance'
    cheat_caller_address(contract_address, spender, CheatSpan::TargetCalls(1));
    erc20_token.transfer_from(OWNER, TOKEN_RECIPIENT, transfer_amount);
}

const USER: ContractAddress = 'USER'.try_into().unwrap();

#[test]
#[feature("safe_dispatcher")]
fn test_mint_non_owner_error_with_safe_dispatcher() {
    // Deploy the HelloStarknet contract with OWNER as the owner
    let contract_address = deploy_contract("ERC20", OWNER);

    // Use the safe dispatcher variant to handle errors gracefully
    let safe_dispatcher = IERC20SafeDispatcher { contract_address };

    // Impersonate USER who is NOT the owner
    start_cheat_caller_address(contract_address, USER);

    // Call increase_balance - this will fail but return a Result instead of panicking
    match safe_dispatcher.mint(TOKEN_RECIPIENT, 100) {
        // If the call succeeds, the test should fail because non-owners shouldn't have access
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        // If the call fails (expected), confirm we get the correct error message
        Result::Err(panic_data) => {
            // Check that the first element of panic_data contains our expected error message
            assert(*panic_data.at(0) == 'Call not owner', 'Wrong error message');
        },
    }

    // stop the caller impersonation
    stop_cheat_caller_address(contract_address);
}


#[test]
#[feature("safe_dispatcher")]
fn test_mint_increase_recipient_correctly() {
    // Deploy the contract
    let contract_address = deploy_contract("ERC20", OWNER);

    // Create dispatcher to interact with the contract
    let erc20_token = IERC20Dispatcher { contract_address };

    // Calculate mint amount: 1000 tokens adjusted for decimals
    let token_decimal = erc20_token.decimals();
    let mint_amount = 1000 * token_decimal.into();

    // Impersonate the owner for the next function call (mint)
    cheat_caller_address(contract_address, OWNER, CheatSpan::TargetCalls(1));
    erc20_token.mint(TOKEN_RECIPIENT, mint_amount);

    // Get the user amount
    let recipient_balance = erc20_token.balance_of(TOKEN_RECIPIENT);

    // Verify recipient_balance matches the minted amount
    assert(recipient_balance == mint_amount, 'Incorrect Supply');
}
