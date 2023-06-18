// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";

import {Flow} from "../contracts/Flow.sol";
import {GaugeFactory} from "../contracts/factories/GaugeFactory.sol";
import {BribeFactory} from "../contracts/factories/BribeFactory.sol";
import {PairFactory} from "../contracts/factories/PairFactory.sol";
import {Router} from "../contracts/Router.sol";
import {VelocimeterLibrary} from "../contracts/VelocimeterLibrary.sol";
import {VeArtProxy} from "../contracts/VeArtProxy.sol";
import {VotingEscrow} from "../contracts/VotingEscrow.sol";
import {RewardsDistributor} from "../contracts/RewardsDistributor.sol";
import {Voter} from "../contracts/Voter.sol";
import {Minter} from "../contracts/Minter.sol";
import {MintTank} from "../contracts/MintTank.sol";
import {AirdropClaim} from "../contracts/AirdropClaim.sol";
import {OptionToken} from "../contracts/OptionToken.sol";
import {IERC20} from "../contracts/interfaces/IERC20.sol";
import {IPair} from "../contracts/interfaces/IPair.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

// new ones
import {GaugeV2} from "..contracts/GaugeV2.sol";
import {OptionToken} from "../contracts/OptionTokenV2.sol";

contract Deployment is Script {
    // token addresses
    // TODO: check token address
    address private constant WPLS = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;
    address private constant USDC = 0x15D38573d2feeb82e7ad5187aB8c1D52810B1f07;
    address private constant DAI = 0xefD766cCb38EaF1dfd701853BFCe31359239F305;
    address private constant WETH = 0x02DcdD04e3F455D838cd1249292C58f3B79e3C3C;
    address private constant WBTC = 0xb17D901469B9208B17d916112988A3FeD19b5cA1;
    address private constant USDT = 0x0Cb6F5a34ad42ec934882A05265A7d5F59b51A2f;
    address private constant HEX = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
   // address private constant BLOTR = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39; 
   // address private constant AGG = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
   // address private constant FLOW = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;

    // privileged accounts
    // TODO: change these accounts!
    address private constant TEAM_MULTI_SIG =
        0xA3082Df7a11071db5ed0e02d48bca5f471dDbaF4;
    address private constant TANK = 0x1bAe1083CF4125eD5dEeb778985C1Effac0ecC06;
    address private constant DEPLOYER =
        0x7e4fB7276353cfa80683F779c20bE9611F7536e5;
    // TODO: set the following variables
    uint private constant INITIAL_MINT_AMOUNT = 315_000_000e18;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);




        // Option to buy Flow
        OptionToken oFlow = new OptionToken(
            "Option to buy FLOW", // name
            "oFLOW", // symbol
            TEAM_MULTI_SIG, // admin
            ERC20(WPLS), // payment token
            ERC20(address(flow)), // underlying token
            flowWplsPair, // pair
            address(gaugeFactory), // gauge factory
            TEAM_MULTI_SIG, // treasury
            50 // discount
        );



        vm.stopBroadcast();
    }
}
