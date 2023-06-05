// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {IFlow} from "../contracts/interfaces/IFlow.sol";
import {AirdropClaim} from "../contracts/AirdropClaim.sol";

contract AirdropClaimDeployment is Script {
    // TODO: set variables
    address private constant FLOW = 0x39b9D781dAD0810D07E24426c876217218Ad353D;
    address private constant VOTING_ESCROW = 0xe7b8F4D74B7a7b681205d6A3D231d37d472d4986;
    address private constant TEAM_MULTI_SIG = 0xA3082Df7a11071db5ed0e02d48bca5f471dDbaF4;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // AirdropClaim
        AirdropClaim airdropClaim = new AirdropClaim(
            FLOW,
            VOTING_ESCROW,
            TEAM_MULTI_SIG
        );

        vm.stopBroadcast();
    }
}
