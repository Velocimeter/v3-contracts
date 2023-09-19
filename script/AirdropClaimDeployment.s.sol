// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {IFlow} from "../contracts/interfaces/IFlow.sol";
import {AirdropClaim} from "../contracts/AirdropClaim.sol";

contract AirdropClaimDeployment is Script {
    // TODO: set variables
    address private constant BVM = 0xE2244F3c62F4b313Cf9C5371c19E9ec9c89b8641;
    address private constant OBVM = 0x9240b391Be56f7845623057357aF5cf367cd762C;
    address private constant TEAM_MULTI_SIG = 0x5b86A94b14Df577cCf2eA19d4f28560161B77715;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // AirdropClaim
        AirdropClaim airdropClaim = new AirdropClaim(
            BVM,
            OBVM,
            TEAM_MULTI_SIG
        );

        //airdropClaim.setOwner(TEAM_MULTI_SIG);

        vm.stopBroadcast();
    }
}
