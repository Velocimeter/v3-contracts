// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {veFlowBooster} from "../contracts/veFlowBooster.sol";

contract veFlowBoosterDeployment is Script {
    // TODO: set variables
    address private constant SCANTO = 0x9F823D534954Fc119E31257b3dDBa0Db9E2Ff4ed;
    address private constant TEAM_MULTI_SIG = 0x13eeB8EdfF60BbCcB24Ec7Dd5668aa246525Dc51;
    address private constant Router = 0x2c8F86334552d062A0d7465C7f524eff15AB046c;
    address private constant VotingEscrow = 0xA1B589FB7e04d19CEC391834131158f7F9d2D168;

    uint256 public constant FULL_LOCK = 2 * 365 * 86400; // 2 years
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        veFlowBooster veFlowBoosterContract = new veFlowBooster(VotingEscrow,TEAM_MULTI_SIG,SCANTO,FULL_LOCK,Router);

        vm.stopBroadcast();
        
    }
}