// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {Voter} from "../contracts/Voter.sol";
import {OptionTokenV2} from "../contracts/OptionTokenV2.sol";
import {GaugeV2} from "../contracts/GaugeV2.sol";
import {GaugeFactoryV2} from "../contracts/factories/GaugeFactoryV2.sol";

contract OFvmSetupTest is Script {
     address private constant VoterAddress = 0xc9Ea7A2337f27935Cd3ccFB2f725B0428e731FBF;
     address private constant oFVM = 0xF9EDdca6B1e548B0EC8cDDEc131464F462b8310D;
     address[] OTokenGauges;
     address[] NormalGauges;
    
    function run() external {
         console2.log("GaugeFactory check");
         address gaugeFactoryAddress =  Voter(VoterAddress).gaugeFactories(0);
         bytes32 oTokenMinterRole = OptionTokenV2(oFVM).MINTER_ROLE();
         bool oTokenSet =  GaugeFactoryV2(gaugeFactoryAddress).oFlow() == oFVM;
         GaugeFactoryV2(gaugeFactoryAddress).oFlow;
         console2.log(gaugeFactoryAddress);
         console2.log("oTokenSet");
         console2.log(oTokenSet);
         console2.log("--------");
         console2.log("Gauge check");
         for(uint i=0;i<Voter(VoterAddress).length();i++) {
           address poolAddress =  Voter(VoterAddress).pools(i);
           address gaugeAddress = Voter(VoterAddress).gauges(poolAddress);
           if(gaugeAddress != address(0x0)) {
                console2.log(gaugeAddress);
                bool oTokenSetGauge =  GaugeV2(gaugeAddress).oFlow() == oFVM;
                console2.log("oTokenSet");
                console2.log(oTokenSetGauge);
                bool oTokenMinterRole =  OptionTokenV2(oFVM).hasRole(oTokenMinterRole, gaugeAddress);
                console2.log("oToken Minter Role");
                console2.log(oTokenMinterRole);
                console2.log("--------");
                if(oTokenSetGauge && oTokenMinterRole) {
                    OTokenGauges.push(gaugeAddress);
                } else {
                    NormalGauges.push(gaugeAddress);
                }
           }
        }

        console2.log("--------");
        console2.log("New gauges");
        if(oTokenSet) {
            console2.log("oFVM");
        } else {
            console2.log("FVM");
        }
        console2.log("--------");
        console2.log("oFVM Gauges");
        for(uint i=0; i<OTokenGauges.length;i++) {
            console2.log(OTokenGauges[i]);
        }
        console2.log("--------");
        console2.log("FVM Gauges");
        for(uint i=0; i<NormalGauges.length;i++) {
            console2.log(NormalGauges[i]);
        }
        console2.log("--------");
    }
}