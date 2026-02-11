use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC20<TContractState> {
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn decimals(self: @TContractState) -> u8;
    fn total_supply(self: @TContractState) -> u256;
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    ) -> bool;
}


#[starknet::contract]
pub mod ERC20 {
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    pub struct Storage {
        // Maps each account address to their token balance
        balances: Map<ContractAddress, u256>,
        // Maps (owner, spender) pairs to approved spending amounts
        allowances: Map<(ContractAddress, ContractAddress), u256>,
        // Token metadata
        token_name: ByteArray,
        symbol: ByteArray,
        decimal: u8,
        // Total number of tokens that exist
        total_supply: u256,
        // Address that can mint new tokens
        owner: ContractAddress,
    }

    // Define the events that this contract can emit
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Transfer: Transfer, // Emitted when tokens are transferred
        Approval: Approval // Emitted when spending approval is granted
    }

    // Event emitted whenever tokens are transferred between addresses
    #[derive(Drop, starknet::Event)]
    pub struct Transfer {
        #[key] // Indexed field (can be filtered when querying events)
        from: ContractAddress, // Address sending the tokens
        #[key] // Indexed field (can be filtered when querying events)
        to: ContractAddress, // Address receiving the tokens
        amount: u256 // Number of tokens transferred
    }

    // Event emitted when an owner approves a spender to use their tokens
    #[derive(Drop, starknet::Event)]
    pub struct Approval {
        #[key] // Indexed field (can be filtered when querying events)
        owner: ContractAddress, // Address that owns the tokens
        #[key] // Indexed field (can be filtered when querying events)
        spender: ContractAddress, // Address approved to spend the tokens
        value: u256 // Amount approved for spending
    }

    //NEWLY ADDED
    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // Set the token's metadata
        self.token_name.write("Rare Token");
        self.symbol.write("RST");
        self.decimal.write(18);

        // Set owner
        self.owner.write(owner); // Usually the deployer's address
    }

    #[abi(embed_v0)]
    impl ERC20Impl of super::IERC20<ContractState> {
        // Returns the full name of the token
        fn name(self: @ContractState) -> ByteArray {
            self.token_name.read()
        }

        // Returns the token's symbol/ticker
        fn symbol(self: @ContractState) -> ByteArray {
            self.symbol.read()
        }

        // Returns the number of decimal places for the token
        fn decimals(self: @ContractState) -> u8 {
            self.decimal.read()
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            // Only the contract owner is allowed to mint new tokens
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Call not owner');

            let cur = self.total_supply();
            let cur_user = self.balances.entry(recipient).read();

            self.total_supply.write(cur + amount);
            self.balances.entry(recipient).write(cur_user + amount);

            // Emit transfer from zero address
            let zero_address: ContractAddress = 0.try_into().unwrap();
            self.emit(Transfer { from: zero_address, to: recipient, amount });

            true
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();

            let sender_prev_balance = self.balances.entry(sender).read();
            assert(sender_prev_balance >= amount, 'Insufficient amount');
            let recipient_prev_balance = self.balances.entry(recipient).read();

            self.balances.entry(sender).write(sender_prev_balance - amount);
            self.balances.entry(recipient).write(recipient_prev_balance + amount);

            // Emit an event to log this Transfer
            self.emit(Transfer { from: sender, to: recipient, amount });

            true
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.entry(account).read()
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress,
        ) -> u256 {
            self.allowances.entry((owner, spender)).read()
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            self.allowances.entry((caller, spender)).write(amount);

            // Emit an event to log this Approval
            self.emit(Approval { owner: caller, spender, value: amount });

            true
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) -> bool {
            let caller = get_caller_address();

            let caller_allowance = self.allowances.entry((sender, caller)).read();
            self.allowances.entry((sender, caller)).write(caller_allowance - amount);

            let sender_prev_balance = self.balances.entry(sender).read();
            let recipient_prev_balance = self.balances.entry(recipient).read();

            self.balances.entry(sender).write(sender_prev_balance - amount);
            self.balances.entry(recipient).write(recipient_prev_balance + amount);

            // Emit an event to log this Transfer
            self.emit(Transfer { from: sender, to: recipient, amount });

            true
        }
    }
}
