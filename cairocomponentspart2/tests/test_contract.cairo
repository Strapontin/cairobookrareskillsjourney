use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::cheatcodes::execution_info::contract_address;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress, SyscallResultTrait};

#[starknet::interface]
trait IRareToken<TContractState> {
    fn pause(ref self: TContractState);
    fn unpause(ref self: TContractState);
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn burn(ref self: TContractState, amount: u256);
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn total_supply(self: @TContractState) -> u256;

    fn decimals(self: @TContractState) -> u8;
}

const OWNER: ContractAddress = 'OWNER'.try_into().unwrap();
const USER: ContractAddress = 'USER'.try_into().unwrap();
const RECIPIENT: ContractAddress = 'RECIPIENT'.try_into().unwrap();

fn deploy_token() -> (ContractAddress, IERC20Dispatcher, IRareTokenDispatcher) {
    let contract = declare("RareToken").unwrap_syscall().contract_class();
    let mut constructor_args = array![OWNER.into()];
    let (contract_address, _) = contract.deploy(@constructor_args).unwrap_syscall();
    let token = IERC20Dispatcher { contract_address };
    let rare_token = IRareTokenDispatcher { contract_address };
    (contract_address, token, rare_token)
}

#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn test_pause_prevents_transfer() {
    let (contract_address, token, rare_token) = deploy_token();

    // Get token decimals for proper amount calculation
    let token_decimal = rare_token.decimals();
    let amount_to_mint: u256 = 10000 * token_decimal.into();

    // Mint tokens to USER
    start_cheat_caller_address(contract_address, OWNER);
    rare_token.mint(USER, amount_to_mint);

    // Pause the contract
    rare_token.pause();
    stop_cheat_caller_address(contract_address);

    // Try to transfer - should fail when paused
    start_cheat_caller_address(contract_address, USER);
    token.transfer(RECIPIENT, 100 * token_decimal.into()); // This should panic
}

#[test]
fn test_unpause_allows_transfer() {
    let (contract_address, token, rare_token) = deploy_token();

    // Get token decimals for proper amount calculation
    let token_decimal = rare_token.decimals();
    let amount_to_mint: u256 = 1000 * token_decimal.into();

    // Mint tokens to USER
    start_cheat_caller_address(contract_address, OWNER);
    rare_token.mint(USER, amount_to_mint);

    // Pause then unpause the contract
    rare_token.pause();
    rare_token.unpause();
    stop_cheat_caller_address(contract_address);

    // Transfer should now succeed
    start_cheat_caller_address(contract_address, USER);
    token.transfer(RECIPIENT, 100 * token_decimal.into());

    // Verify the transfer worked*
    assert!(token.balance_of(USER) == 900 * token_decimal.into(), "User balance incorrect");
    assert!(
        token.balance_of(RECIPIENT) == 100 * token_decimal.into(), "Recipient balance incorrect",
    );
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_only_owner_can_pause() {
    let (contract_address, _token, rare_token) = deploy_token();

    // Try to pause as non-owner - should panic
    start_cheat_caller_address(contract_address, USER);
    rare_token.pause();
    // no need to stop cheat since it doesn't reach here
}

#[test]
fn test_user_can_burn_their_own_tokens() {
    let (contract_address, _token, rare_token) = deploy_token();

    // Mint tokens to USER
    let token_decimal = rare_token.decimals();
    let amount_to_mint: u256 = 10000 * token_decimal.into();
    start_cheat_caller_address(contract_address, OWNER);
    rare_token.mint(USER, amount_to_mint);

    start_cheat_caller_address(contract_address, USER);
    rare_token.burn(amount_to_mint / 2);
}

#[test]
fn test_user_can_burning_decrease_balance_and_total_supply() {
    let (contract_address, _token, rare_token) = deploy_token();

    // Mint tokens to USER
    let token_decimal = rare_token.decimals();
    let amount_to_mint: u256 = 10000 * token_decimal.into();
    start_cheat_caller_address(contract_address, OWNER);
    rare_token.mint(USER, amount_to_mint);

    let user_balance_before = rare_token.balance_of(USER);
    let total_supply_before = rare_token.total_supply();

    start_cheat_caller_address(contract_address, USER);
    rare_token.burn(amount_to_mint / 2);

    let user_balance_after = rare_token.balance_of(USER);
    let total_supply_after = rare_token.total_supply();

    assert!(
        user_balance_after == user_balance_before - amount_to_mint / 2,
        "User balance should have decreased after burn",
    );
    assert!(
        total_supply_after == total_supply_before - amount_to_mint / 2,
        "User balance should have decreased after burn",
    );
}


#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn test_burning_fail_when_contract_paused() {
    let (contract_address, _token, rare_token) = deploy_token();

    // Mint tokens to USER
    let token_decimal = rare_token.decimals();
    let amount_to_mint: u256 = 10000 * token_decimal.into();

    start_cheat_caller_address(contract_address, OWNER);
    rare_token.mint(OWNER, amount_to_mint);
    rare_token.pause();

    rare_token.burn(1);
}

#[test]
#[should_panic(expected: ('ERC20: insufficient balance',))]
fn test_user_cannot_burn_more_tokens_than_they_have() {
    let (contract_address, _token, rare_token) = deploy_token();

    // Mint tokens to USER
    let token_decimal = rare_token.decimals();
    let amount_to_mint: u256 = 10000 * token_decimal.into();
    start_cheat_caller_address(contract_address, OWNER);
    rare_token.mint(USER, amount_to_mint);

    start_cheat_caller_address(contract_address, USER);
    rare_token.burn(amount_to_mint * 2);
}
