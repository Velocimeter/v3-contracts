// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {IFlow} from "../contracts/interfaces/IFlow.sol";
import {StandaloneGauge} from "../contracts/StandaloneGauge.sol";

contract FvmGaugeDeployment is Script {
    // TODO: set variables
    address private constant FVM = 0x07BB65fAaC502d4996532F834A1B7ba5dC32Ff96;
    address private constant VOTING_ESCROW = 0xAE459eE7377Fb9F67518047BBA5482C2F0963236;
    address private constant OFVM = 0xF9EDdca6B1e548B0EC8cDDEc131464F462b8310D;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address[] memory rewards = new address[](2);
        rewards[0] = FVM;
        rewards[1] = OFVM;

        // FvmGauge
        StandaloneGauge standaloneGauge = new StandaloneGauge(
            FVM,
            VOTING_ESCROW,
            OFVM,
            rewards
        );

        vm.stopBroadcast();
    }
}
