// // Event emitted when a new user registers
// #[derive(Drop, starknet::Event)]
// pub struct UserRegistered {
//     #[key] // Marking the next element as indexed (searchable key)
//     pub user_id: u32,
//     pub username: ByteArray
// }

// Event emitted when a user logs in
#[derive(Drop, starknet::Event)]
pub struct UserLoggedIn {
    pub user_id: u32,
    pub timestamp: u64
}

// Main event enum that holds all possible events this contract can emit
#[event]
#[derive(Drop, starknet::Event)]
pub enum Event {
    NewUser: UserRegistered,   // references UserRegistered struct
    UserLogin: UserLoggedIn    // references UserLoggedIn struct
}


#[derive(Drop, starknet::Event)]
pub struct UserRegistered {
    #[key]
    pub user_id: u32,
    pub username: ByteArray,
    pub metadata: UserMetadata,
    pub tag_count: u32,
    pub timestamp: u64,
}

#[derive(Drop, Serde)]
pub struct UserMetadata {
    pub device_type: ByteArray,
    pub ip_region: ByteArray,
}

// OUTER enum (the main Event enum)
pub enum EventToFlat {
    UserRegistered: UserRegistered,
    #[flat]
    UserDataUpdated: UserDataUpdated,  // <- This references the INNER enum
}

// INNER enum (nested inside the outer enum structure)
pub enum UserDataUpdated {
    DeviceType: UpdatedDeviceType,     // <- These are the inner variants
    IpRegion: UpdatedIpRegion,         // <- These are the inner variants
}

// Event for device type updates
#[derive(Drop, starknet::Event)]
pub struct UpdatedDeviceType {
    #[key]
    pub user_id: u32,                         // Indexed user ID
    pub new_device_type: ByteArray,           // New device type value
}

// Event for IP region updates
#[derive(Drop, starknet::Event)]
pub struct UpdatedIpRegion {
    #[key]
    pub user_id: u32,                         // Indexed user ID
    pub new_ip_region: ByteArray,             // New IP region value
}