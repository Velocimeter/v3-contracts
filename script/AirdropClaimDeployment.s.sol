// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {IFlow} from "../contracts/interfaces/IFlow.sol";
import {AirdropClaim} from "../contracts/AirdropClaim.sol";

contract AirdropClaimDeployment is Script {
    // TODO: set variables
    address private constant FLOW = 0xE1689e9AaD6b36D91E357FAf95cd7c2C4C1b5475;
    address private constant VOTING_ESCROW = 0x34172780901eF075C67942392Ab461186d8C8cc5;
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
