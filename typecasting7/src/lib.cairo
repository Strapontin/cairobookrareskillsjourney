use starknet::ContractAddress;

fn safe_convert_felt_to_u8(felt_value: felt252) -> Option<u8> {
    felt_value.try_into()
}

fn main() {
    let small_felt: felt252 = 100;
    let large_felt: felt252 = 1000;

    let small_as_u8 = safe_convert_felt_to_u8(small_felt); // Returns Some(100)
    println!("Small conversion result: {:?}", small_as_u8);

    let large_as_u8 = safe_convert_felt_to_u8(large_felt); // Returns None

    // handle the successful conversion
    match small_as_u8 {
        Option::Some(val) => println!("Successfully converted 100 to u8: {}", val),
        Option::None => println!("Small conversion failed"),
    }

    // handle the failed conversion
    match large_as_u8 {
        Option::Some(val) => println!("Converted: {}", val),
        Option::None => println!("Conversion failed: 1000 is too large for u8"),
    }
}

fn safe_convert_u256_to_address(value: u256) -> Option<ContractAddress> {
    // First step: try to convert u256 to felt252 (might fail if value is too large)
    match value.try_into() {
        Option::Some(felt_val) => {
            // u256 to felt252 conversion succeeded
            let address_felt: felt252 = felt_val;
            // Second step: try to convert felt252 to ContractAddress
            // This can also fail if the felt252 value is outside valid address range
            address_felt.try_into()
        },
        Option::None => {
            // u256 to felt252 conversion failed (value too large for felt252)
            Option::None
        }
    }
}