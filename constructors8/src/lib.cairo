#[starknet::interface]
pub trait IHelloStarknet<TContractState> {
}

#[starknet::contract]
pub mod HelloStarknet {
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerWriteAccess};

    // `Account` STRUCT
    #[derive(Drop, Serde, starknet::Store)]
    pub struct Account {
        pub wallet: ContractAddress,
        pub balance: u64,
    }

    #[storage]
    struct Storage {
        // Use the `Account` struct in storage
        pub user_account: Account,
    }

    // Constructor function
    #[constructor]
    // Each field is declared as its own constructor argument
    fn constructor(
            ref self: ContractState,
            new_user_account: Account,
        ) {

        // WRITE `new_user_account` STRUCT TO STORAGE
        self.user_account.write(new_user_account);

    }
}


/////////////////////////////////////////////////



#[starknet::interface]
pub trait IContractTwo<TContractState> {
    fn increase_balance(ref self: TContractState, amount: felt252);
    fn get_balance(self: @TContractState) -> felt252;
}

#[starknet::contract]
mod ContractTwo {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        balance: felt252,
    }

    // ************************ NEWLY ADDED - START ***********************//
    #[constructor]
    fn constructor(ref self: ContractState) -> felt252 {
        33
    }
    // ************************ NEWLY ADDED - END ************************//

    #[abi(embed_v0)]
    impl ContractTwoImpl of super::IContractTwo<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            self.balance.write(self.balance.read() + amount);
        }

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }
    }
}
