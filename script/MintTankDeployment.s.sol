// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {IFlow} from "../contracts/interfaces/IFlow.sol";
import {MintTank} from "../contracts/MintTank.sol";

contract MintTankDeployment is Script {
    // TODO: set variables
    address private constant FLOW = 0xE2244F3c62F4b313Cf9C5371c19E9ec9c89b8641;
    address private constant VOTING_ESCROW = 0x762D6b449fFaC41DFDA9C9f3a22004F496cE7c80;
    address private constant TEAM_MULTI_SIG = 0x5b86A94b14Df577cCf2eA19d4f28560161B77715;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // AirdropClaim
        MintTank mintTank = new MintTank(
            FLOW,
            VOTING_ESCROW,
            TEAM_MULTI_SIG,
            52 * 7 * 86400
        );

        vm.stopBroadcast();
    }
}
