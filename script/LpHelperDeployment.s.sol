// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {LpHelper} from "../contracts/LpHelper.sol";

contract LpHelperDeployment is Script {
    // TODO: amend addresses
    address private constant TEAM_MULTI_SIG = 0x6738fF9bCE566b4F80bB604e18b9bA3B0daE60cA;
    address private constant PAIR_FACTORY =
        0x6738fF9bCE566b4F80bB604e18b9bA3B0daE60cA;
    address private constant VOTER =
        0x34bAa0b40dc2Bd98c9fdDd5121Ba1bB855870338;
    address payable private constant ROUTER =
        payable(0x91aC12C15B8e9ac90d1585c7A586555d167cAb5B);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Option to buy Flow
        LpHelper lpHelper = new LpHelper(
            ROUTER,
            VOTER,
            PAIR_FACTORY,
            TEAM
        );

        vm.stopBroadcast();
    }
}
