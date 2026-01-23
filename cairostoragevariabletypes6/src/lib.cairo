#[starknet::interface]
pub trait IHelloStarknet<TContractState> {
    fn write_vars(ref self: TContractState);
    fn read_vars(self: @TContractState);
}

#[starknet::contract]
mod HelloStarknet {
    use starknet::storage::{
        Map, MutableVecTrait, StorageMapReadAccess, StorageMapWriteAccess, StoragePathEntry,
        StoragePointerReadAccess, StoragePointerWriteAccess, Vec, VecTrait,
    };
    use starknet::{ContractAddress, get_caller_address};

    // Struct
    #[derive(starknet::Store)]
    struct UserData {
        id: u32,
        name: bytes31,
        is_admin: bool,
    }
    #[derive(starknet::Store, Drop)]
    enum UserRole {
        Admin,
        Mod,
        #[default]
        User,
    }

    //  STRUCT: This will NOT work ❌ - Vec has dynamic size
    // #[derive(starknet::Store)]
    // struct InvalidUser {
    //     name: felt252,
    //     balance: u256,
    //     friends: Vec<ContractAddress>, // ERROR: Cannot store Vec in struct
    //     tokenBal: Map<ContractAddress, u256> // ERROR: Cannot store Map in struct
    // }

    //  ENUM: This will also NOT work ❌ - Map has dynamic size
    // #[derive(starknet::Store)]
    // enum InvalidUserRole {
    //     Admin: Map<felt252, bool>, // ERROR: Cannot store Map in enum variant
    //     #[default]
    //     User,
    // }

    //? If we need to store collections inside a struct, we have to use a special kind of struct
    //called storage node.

    // Storage node - CAN contain collections
    #[starknet::storage_node]
    struct UserStorageNode {
        name: felt252,
        balance: u256,
        friends: Vec<ContractAddress>, // ✅ Now allowed!
        tokenBal: Map<ContractAddress, u256> // ✅ Also allowed!
    }


    #[storage]
    struct Storage {
        user_id: felt252,
        total_supply: u256,
        is_paused: bool,
        contract_name: bytes31,
        contract_description: ByteArray,
        owner_address: ContractAddress,
        version_info: (u8, i8),
        // mapping(address => uint256) my_map;
        my_map: Map<ContractAddress, u256>,
        // uint64[] my_vec;
        my_vec: Vec<u64>,
        // user_address => token_address => balance (requires StoragePathEntry)
        two_level_mapping: Map<ContractAddress, Map<ContractAddress, u256>>,
        user: UserData,
        my_role: UserRole,
        user_data: UserStorageNode,
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
        fn write_vars(ref self: ContractState) {
            // Writing to felt252
            self.user_id.write(12345);

            // Writing to u256
            self.total_supply.write(1000000_u256);

            // Writing to bool
            self.is_paused.write(false);

            // Writing to bytes31 (short string)
            self.contract_name.write('HelloContract'.try_into().unwrap());

            // Writing to ByteArray (long string)
            self.contract_description.write("This is a very very very long textttt");

            // Writing to ContractAddress
            self.owner_address.write(0x1234.try_into().unwrap());

            // Writing to tuple
            self.version_info.write((1_u8, -2_i8));
        }

        fn read_vars(self: @ContractState) {
            // felt252: Reading user ID returns a field element (0 to P-1 range)
            let _ = self.user_id.read();

            // u256: Reading large integer, useful for token balances and big numbers
            let _ = self.total_supply.read();

            // bool: Reading boolean state, returns true or false
            let _ = self.is_paused.read();

            // bytes31: Reading fixed-size byte array, used for short strings
            let _ = self.contract_name.read();

            // ByteArray: Reading dynamic-size byte array, used for long strings
            let _ = self.contract_description.read();

            // ContractAddress: Reading Starknet address, type-safe contract/user address
            let _ = self.owner_address.read();

            // Tuple: Reading compound type returns both values as (u8, i8) pair
            let _ = self.version_info.read();
        }
    }

    // mapping
    fn write_to_mapping(ref self: ContractState, user: ContractAddress, amount: u256) {
        self.my_map.write(user, amount); // write operation
    }
    fn get_value(self: @ContractState, user: ContractAddress) -> u256 {
        self.my_map.read(user) // read operation
    }

    // nested mapping
    fn write_nested_map(
        ref self: ContractState, key1: ContractAddress, key2: ContractAddress, value: u256,
    ) {
        // WRITE OPERATION
        self.two_level_mapping.entry(key1).entry(key2).write(value);
    }
    fn read_nested_map(
        ref self: ContractState, key1: ContractAddress, key2: ContractAddress,
    ) -> u256 {
        // READ OPERATION
        self.two_level_mapping.entry(key1).entry(key2).read()
    }

    fn write_nested_map_lvl1(
        ref self: ContractState, key1: ContractAddress, key2: ContractAddress, value: u256,
    ) {
        // WRITE OPERATION
        self.two_level_mapping.entry(key1).write(key2, value);
    }
    fn read_nested_map_lvl1(
        ref self: ContractState, key1: ContractAddress, key2: ContractAddress,
    ) -> u256 {
        // READ OPERATION
        self.two_level_mapping.entry(key1).read(key2)
    }

    // vec (array)
    fn push_number(ref self: ContractState, value: u64) {
        // PUSH OPERATION
        self.my_vec.push(value);
    }
    fn read_my_vec(self: @ContractState, index: u64) -> u64 {
        // VEC READ OPERATION
        self.my_vec.at(index).read() // Will panic if index is out of bounds
    }
    fn write_my_vec(ref self: ContractState, index: u64, val: u64) {
        // VEC WRITE OPERATION
        self.my_vec.at(index).write(val) // Will panic if index is out of bounds
    }
    fn get_vec_len(self: @ContractState) -> u64 {
        // RETURN VEC LENGTH
        self.my_vec.len()
    }
    fn pop_last(ref self: ContractState) {
        // POP OPERATION
        let _ = self.my_vec.pop();
    }

    // Struct
    fn write_struct(ref self: ContractState, _id: u32, _name: bytes31, _is_admin: bool) {
        self.user.id.write(_id); // Write to field 1
        self.user.name.write(_name); // Write to field 2
        self.user.is_admin.write(_is_admin); // Write to field 3
    }
    fn read_struct(ref self: ContractState) -> (u32, bytes31, bool) {
        let id = self.user.id.read(); // Read from field 1
        let name = self.user.name.read(); // Read from field 2
        let is_admin = self.user.is_admin.read(); // Read from field 3

        (id, name, is_admin)
    }

    // Enum
    fn write_enum(ref self: ContractState) {
        // Write the Admin variant to storage
        self.my_role.write(UserRole::Admin);
    }
    fn read_enum(self: @ContractState) {
        // Read the current value of the enum from storage
        let _ = self.my_role.read();
    }

    // Storage node
    fn write_nodes(ref self: ContractState) {
        // Write to simple fields (felt252 and u256)
        self.user_data.name.write(3);
        self.user_data.balance.write(1000_u256);

        // Push a new address to the friends vector
        self.user_data.friends.push(get_caller_address());

        // Write to nested map using either of the two valid approaches
        // Approach 1
        self.user_data.tokenBal.entry(get_caller_address()).write(23);
        // Approach 2
        self.user_data.tokenBal.write(get_caller_address(), 23);
    }
    fn read_nodes(self: @ContractState) {
        // Read simple values
        let _ = self.user_data.name.read();
        let _ = self.user_data.balance.read();

        // Read a value from the vector at index 0
        let _ = self.user_data.friends.at(0);

        // Read token balance from the nested map
        let _ = self.user_data.tokenBal.read(get_caller_address());
    }
}
