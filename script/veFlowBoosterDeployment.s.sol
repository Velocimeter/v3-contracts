// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {veFlowBooster} from "../contracts/veFlowBooster.sol";

contract veFlowBoosterDeployment is Script {
    // TODO: set variables
    address private constant FVM = 0x07BB65fAaC502d4996532F834A1B7ba5dC32Ff96;
    address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address private constant TEAM_MULTI_SIG = 0x88Dec6df03C2C111Efd4ad89Cef2c0347034AFC0;
    address private constant Router = 0x2E14B53E2cB669f3A974CeaF6C735e134F3Aa9BC;
    address private constant VotingEscrow = 0xAE459eE7377Fb9F67518047BBA5482C2F0963236;

    uint256 public constant FULL_LOCK = 52 * 7 * 86400; // 52 weeks
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        veFlowBooster veFlowBoosterContract = new veFlowBooster(VotingEscrow,TEAM_MULTI_SIG,WFTM,FULL_LOCK,Router);

        vm.stopBroadcast();
        
    }
}