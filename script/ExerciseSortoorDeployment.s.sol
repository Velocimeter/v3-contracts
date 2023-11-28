// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {ExerciseSortoor} from "../contracts/ExerciseSortoor.sol";

contract ExerciseSortoorDeployment is Script {
    // TODO: set variables
    address private constant TEAM_MULTI_SIG = 0xfA89A4C7F79Dc4111c116a0f01061F4a7D9fAb73;
    address private constant Router = 0xE11b93B61f6291d35c5a2beA0A9fF169080160cF;
    address private constant veBooster = 0x7503E653Fb91d5531c3A597BcAF0635FB096d795;

    uint256 public constant FULL_LOCK = 52 * 7 * 86400; // 52 weeks
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        ExerciseSortoor exerciseSortoorContract = new ExerciseSortoor(TEAM_MULTI_SIG,veBooster,Router);

        exerciseSortoorContract.setRatio(72);

        exerciseSortoorContract.transferOwnership(TEAM_MULTI_SIG);

        vm.stopBroadcast();
        
    }
}