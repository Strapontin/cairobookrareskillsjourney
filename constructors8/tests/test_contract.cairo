// ********* NEW IMPORTS - START ********* //
use constructors8::HelloStarknet::{Account, deploy_for_test};
use starknet::deployment::DeploymentParams;
// ********** NEW IMPORTS - END ********** //

use snforge_std::{DeclareResult, DeclareResultTrait, declare};
use starknet::ContractAddress;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    // 1. Declare contract to get the class_hash
    let declare_result: DeclareResult = declare(name).unwrap();
    let class_hash = declare_result.contract_class().class_hash;

    // 2. Create deployment parameters
    let deployment_params = DeploymentParams { salt: 0, deploy_from_zero: true };

    // 3. Create new account
    let new_account = Account { wallet: 'BOB'.try_into().unwrap(), balance: 5 };

    // 4. Use `deploy_for_test` to deploy the contract
    // It automatically handles serialization of constructor parameters
    let (_contract_address, _) = deploy_for_test(*class_hash, deployment_params, new_account)
        .expect('Deployment failed');

    _contract_address
}