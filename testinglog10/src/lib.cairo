// Interface defining the functions our UserManager contract will implement
#[starknet::interface]
pub trait IUserManager<TContractState> {
    fn register_user(ref self: TContractState, username: ByteArray);
    fn get_user_count(self: @TContractState) -> u32;
}

// Struct to store user information (derives Store to enable storage in contract)
#[derive(Drop, Serde, starknet::Store)]
pub struct UserMetadata {
    pub user_id: u32,
    pub username: ByteArray,
}

// Event emitted when a new user registers (user_id is marked as key for indexing)
#[derive(Drop, starknet::Event)]
pub struct UserRegistered {
    #[key]
    pub user_id: u32,
    pub username: ByteArray,
    pub timestamp: u64,
}

#[starknet::contract]
pub mod UserManager {
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
    use super::{IUserManager, UserMetadata, UserRegistered};

    #[storage]
    struct Storage {
        user_counter: u32, // Tracks total number of registered users
        users: Map<ContractAddress, UserMetadata> // Maps user addresses to their metadata
    }

    // Main event enum that holds all possible events this contract can emit
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        UserRegistered: UserRegistered,
    }

    #[abi(embed_v0)]
    impl UserManagerImpl of IUserManager<ContractState> {
        fn register_user(ref self: ContractState, username: ByteArray) {
            // Get current user count and increment for new user ID
            let current_counter = self.user_counter.read();
            let user_id = current_counter + 1;

            // Create user metadata with new ID and provided username
            let metadata = UserMetadata { user_id, username: username.clone() };

            // Update counter and store user data mapped to caller's address
            self.user_counter.write(user_id);
            self.users.entry(get_caller_address()).write(metadata);

            // Emit event with user details and current timestamp
            self.emit(UserRegistered { user_id, username, timestamp: get_block_timestamp() });
        }

        fn get_user_count(self: @ContractState) -> u32 {
            // Return the current number of registered users
            self.user_counter.read()
        }
    }
}
