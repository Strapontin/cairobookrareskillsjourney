// the function takes two parameters: `x` and `y`,
// both of type `felt252`, and returns a value of type `felt252`.
fn multiply(x: felt252, y: felt252) -> felt252 {
    // The result of the multiplication expression is implicitly returned.
    x * y
}

// #[executable]
// fn main() {
//    // Calls the multiply function with literal felt252 values: 3 and 4.
//    let result = multiply(3, 4);  // result = 12
//    println!("This is the value of multiply(3, 4): {}", result);
// }

// felt252 Division
use core::felt252_div;

#[executable]
fn main() {
        // (p + 1) / 2
    let P_plus_1_halved = 1809251394333065606848661391547535052811553607665798349986546028067936010241;

    assert!(felt252_div(1, 2) == P_plus_1_halved);
    println!("this is the value of felt252_div(1, 2): {}", felt252_div(1, 2));

    //divisions with zero remainder
    assert!(felt252_div(2, 1) == 2);
    println!("this is the value of felt252_div(2, 1): {}", felt252_div(2, 1));
    assert!(felt252_div(15, 5) == 3);
    println!("this is the value of felt252_div(15, 5): {}", felt252_div(15, 5));

    //division with remainder
    println!("this is the value of felt252_div(7, 3): {}", felt252_div(7, 3));
    println!("this is the value of felt252_div(4, 3): {}", felt252_div(4, 3));

}
