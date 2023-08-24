// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {veFlowBooster} from "../contracts/veFlowBooster.sol";

contract veFlowBoosterDeployment is Script {
    // TODO: set variables
    address private constant GVM = 0xE2244F3c62F4b313Cf9C5371c19E9ec9c89b8641;
    address private constant WFTM = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
    address private constant TEAM_MULTI_SIG = 0x5b86A94b14Df577cCf2eA19d4f28560161B77715;
    address private constant Router = 0x91aC12C15B8e9ac90d1585c7A586555d167cAb5B;
    address private constant VotingEscrow = 0x762D6b449fFaC41DFDA9C9f3a22004F496cE7c80;

    uint256 public constant FULL_LOCK = 52 * 7 * 86400; // 52 weeks
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        veFlowBooster veFlowBoosterContract = new veFlowBooster(VotingEscrow,TEAM_MULTI_SIG,WFTM,FULL_LOCK,Router);

        vm.stopBroadcast();
        
    }
}