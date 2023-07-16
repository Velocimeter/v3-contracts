// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {GaugeFactoryV3} from "../contracts/factories/GaugeFactoryV3.sol";
import {Voter} from "../contracts/Voter.sol";
import {GaugeV3} from "../contracts/GaugeV3.sol";

contract MigrateGauge is Script {
    // TODO: set variables
    address private constant GaugeToBeMigrated = 0x38ED4DC09A7a810053EAC923bff4D1d8C2cF4D62;

    ///////
    address private constant DEPLOYER = 0x3b91Ca4D89B5156d456CbD0D6305F7f36B1517a4;
    address private constant VoterAddress = 0xc9Ea7A2337f27935Cd3ccFB2f725B0428e731FBF;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
 
        address external_bribe = Voter(VoterAddress).external_bribes(GaugeToBeMigrated);
        address pool = Voter(VoterAddress).poolForGauge(GaugeToBeMigrated);

        Voter(VoterAddress).killGaugeTotally(GaugeToBeMigrated);
        address newGauge = Voter(VoterAddress).createGauge(pool, 1);
        Voter(VoterAddress).setExternalBribeFor(newGauge, external_bribe);

        vm.stopBroadcast();
    }
}