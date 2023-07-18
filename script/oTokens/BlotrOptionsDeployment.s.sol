// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import {OptionTokenV2} from "../../contracts/OptionTokenV2.sol";
import {IPair} from "../../contracts/interfaces/IPair.sol";

contract BlotrOptionsDeployment is Script {
    // TODO: set variables
     address private constant DEPLOYER = 0x3b91Ca4D89B5156d456CbD0D6305F7f36B1517a4;


    address private constant TEAM_MULTI_SIG =
        0x88Dec6df03C2C111Efd4ad89Cef2c0347034AFC0;

    address private constant BLOTR =
        0x2A5E4c77F791c0174a717B644A53fc21A29790Cd;
    address private constant SCANTO =
        0x0AeEecbEedB4bC6288EBb9b412341428564709D4;

    address private constant BLOTR_treasury =
        0x58328aE00df6017Dbe83c5F59CaB96430E6926Ae;

    address private constant SCANTO_BLOTR_PAIR =
        0x4a73afbe6E2FEEF9fA23e8D7792eF87a371DF675;


     address private constant VoterAddress = 0xc9Ea7A2337f27935Cd3ccFB2f725B0428e731FBF;
     address private constant GaugeFactory = 0x8691dc917a50FC0881f9107A5Edf4D2605F041bA;
     address private constant Router = 0x2E14B53E2cB669f3A974CeaF6C735e134F3Aa9BC;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

         // Option to buy Flow
        OptionTokenV2 oBLOTR = new OptionTokenV2(
            "Option to buy BLOTR", // name
            "oBLOTR", // symbol
            DEPLOYER, // admin
            SCANTO, // payment token
            BLOTR, // underlying token
            // TODO: change if want to set beforehand
            IPair(SCANTO_BLOTR_PAIR), // pair
            GaugeFactory, // gauge factory
            BLOTR_treasury, // treasury
            VoterAddress,
            address(0), // no excercise to ve
            Router
        );

        oBLOTR.grantRole(oBLOTR.ADMIN_ROLE(), TEAM_MULTI_SIG);

        oBLOTR.setMaxLPDiscount(20);
        oBLOTR.setMinLPDiscount(60);

        oBLOTR.setDiscount(75);

        oBLOTR.setLockDurationForMinLpDiscount(604800);
        oBLOTR.setLockDurationForMaxLpDiscount(5260000);

        oBLOTR.updateGauge();
        
        vm.stopBroadcast();
    }
}

//forge script --rpc-url https://fantom.publicnode.com BlotrOptionsDeployment -vvvvv --slow --verify 