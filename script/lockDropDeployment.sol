// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {LockDropLPTokenV2} from "../contracts/LockDropLPTokenV2.sol";
import {IPair} from "../contracts/interfaces/IPair.sol";


contract lockDropDeployment is Script {
    // TODO: set variables
    address private constant TEAM_MULTI_SIG = 0x28b0e8a22eF14d2721C89Db8560fe67167b71313;
    address private constant WMNT = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8;
    address private constant MVM = 0x861A6Fc736Cbb12ad57477B535B829239c8347d7;
    address private constant PAIR = 0xbdC950638E53E2Ee6728E0A64b094AE4660918e2;
    address private constant GAUGEFACTORY = 0xf19d2e09223b6d0c2f82A84cEF85E951245Ce567;
    address private constant VOTER = 0x2215aB2e64490bC8E9308d0371e708845a796A29;
    address private constant Router = 0xCe30506F6c1Cea34aC704f93d51d55058791E497;
    address private constant VotingEscrow = 0xA906901429F62708A587EA1fC5Fef6C850AA5F9b;

    uint256 public constant FULL_LOCK = 52 * 7 * 86400; // 52 weeks
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOY_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        new LockDropLPTokenV2(
                    "LPDefualtLockdrop",
                    "ldMVMlp",
                    TEAM_MULTI_SIG,
                    WMNT,
                    MVM,
                    IPair(PAIR),
                    GAUGEFACTORY,
                    VOTER,
                    VotingEscrow,
                    Router           
            );


        vm.stopBroadcast();
        
    }
}