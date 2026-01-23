// In a separate file, so no need to wrap the functions with `mod` (the file itself acts like a module)
pub fn internal_mul_by_magic_number(a: felt252) -> felt252 {
    a * private_magic_number()
}

fn private_magic_number() -> felt252 {
    6
}
