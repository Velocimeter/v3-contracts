// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import {OptionTokenV2} from "../../contracts/OptionTokenV2.sol";
import {IPair} from "../../contracts/interfaces/IPair.sol";

contract BayOptionsDeployment is Script {
    
    address private constant DEPLOYER = 0x3b91Ca4D89B5156d456CbD0D6305F7f36B1517a4;

    address private constant TEAM_MULTI_SIG =
        0x88Dec6df03C2C111Efd4ad89Cef2c0347034AFC0;

    address private constant BAY =
        0xE5a4c0af6F5f7Ab5d6C1D38254bCf4Cc26d688ed;
    address private constant WFTM =
        0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    address private constant BAY_treasury =
        0x6c33125eA9e5C54a903326abd521315ff7Ff5D7A;

    address private constant BAY_WFTM_PAIR =
        0xB2eDFd0e318A44826059F35380bec58E8f756664;


     address private constant VoterAddress = 0xc9Ea7A2337f27935Cd3ccFB2f725B0428e731FBF;
     address private constant GaugeFactory = 0x8691dc917a50FC0881f9107A5Edf4D2605F041bA;
     address private constant Router = 0x2E14B53E2cB669f3A974CeaF6C735e134F3Aa9BC;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

         // Option to buy Flow
        OptionTokenV2 oBAY = new OptionTokenV2(
            "Option to buy BAY", // name
            "oBAY", // symbol
            DEPLOYER, // admin
            WFTM, // payment token
            BAY, // underlying token
            // TODO: change if want to set beforehand
            IPair(BAY_WFTM_PAIR), // pair
            GaugeFactory, // gauge factory
            BAY_treasury, // treasury
            VoterAddress,
            address(0), // no excercise to ve
            Router
        );

        oBAY.grantRole(oBAY.ADMIN_ROLE(), TEAM_MULTI_SIG);

        oBAY.grantRole(oBAY.MINTER_ROLE(), BAY_treasury);
        oBAY.grantRole(oBAY.MINTER_ROLE(), 0xa9D3b1408353d05064d47DAF0Dc98E104eb9c98A);

        oBAY.setMaxLPDiscount(20);
        oBAY.setMinLPDiscount(60);

        oBAY.setDiscount(75);

        oBAY.setLockDurationForMinLpDiscount(604800);
        oBAY.setLockDurationForMaxLpDiscount(5260000);

        oBAY.updateGauge();
        
        vm.stopBroadcast();
    }
}

// Needs to be done after the script
// 1. Whitlist the oTokent in the voter
// 2. Add oToken as allowed token to the new v3 gauge

//forge script --rpc-url https://fantom.publicnode.com BlotrOptionsDeployment -vvvvv --slow --verify 