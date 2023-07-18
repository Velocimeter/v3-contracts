// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {GaugeFactoryV3} from "../contracts/factories/GaugeFactoryV3.sol";
import {Voter} from "../contracts/Voter.sol";
import {GaugeV3} from "../contracts/GaugeV3.sol";
import {OptionTokenV2} from "../contracts/OptionTokenV2.sol";

contract MigrateGauge is Script {
    // TODO: set variables
    address private constant GaugeToBeMigrated = 0x5511782e2b9432fd9C8DddecDe886C626aB77E0C;
    address private constant OptionTokenV2Address = 0x269557D887EaA9C1a756B2129740B3FC2821fD91;
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

        // bellow is needed to sync the new gauge with the current state of the rewards distrubuted from minter
        Voter(VoterAddress).pauseGauge(newGauge);
        Voter(VoterAddress).restartGauge(newGauge);

        // refresh gauge in the oToken that is going to be used
        OptionTokenV2(OptionTokenV2Address).updateGauge();

        vm.stopBroadcast();
    }
}