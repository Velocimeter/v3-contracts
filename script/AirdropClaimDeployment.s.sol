// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {IFlow} from "../contracts/interfaces/IFlow.sol";
import {AirdropClaim} from "../contracts/AirdropClaim.sol";

contract AirdropClaimDeployment is Script {
    // TODO: set variables
    address private constant FLOW = 0x07BB65fAaC502d4996532F834A1B7ba5dC32Ff96;
    address private constant VOTING_ESCROW = 0xAE459eE7377Fb9F67518047BBA5482C2F0963236;
    address private constant TEAM_MULTI_SIG = 0x88Dec6df03C2C111Efd4ad89Cef2c0347034AFC0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // AirdropClaim
        AirdropClaim airdropClaim = new AirdropClaim(
            FLOW,
            VOTING_ESCROW,
            TEAM_MULTI_SIG
        );

        airdropClaim.setOwner(TEAM_MULTI_SIG);

        vm.stopBroadcast();
    }
}
