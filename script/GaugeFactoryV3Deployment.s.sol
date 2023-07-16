// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {GaugeFactoryV3} from "../contracts/factories/GaugeFactoryV3.sol";

contract GaugeFactoryV3Deployment is Script {
    // TODO: set variables
    address private constant DEPLOYER = 0x3b91Ca4D89B5156d456CbD0D6305F7f36B1517a4;
    address private constant oFVM = 0xF9EDdca6B1e548B0EC8cDDEc131464F462b8310D;
    address private constant TEAM_MULTI_SIG =
        0x88Dec6df03C2C111Efd4ad89Cef2c0347034AFC0;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
 
        GaugeFactoryV3 gaugeFactoryV3 = new GaugeFactoryV3();

        gaugeFactoryV3.setOFlow(oFVM);
        
        gaugeFactoryV3.transferOwnership(TEAM_MULTI_SIG);

        vm.stopBroadcast();
    }
}
