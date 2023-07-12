// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

// Scripting tool
import "forge-std/console2.sol";
import {Script} from "../lib/forge-std/src/Script.sol";
import {MintTank} from "../contracts/MintTank.sol";
import {Voter} from "../contracts/Voter.sol";

contract Rebater is Script { 

    // partner destinations
    address constant DUES = 0x83B285E802D76055169B1C5e3bF21702B85b89Cb;
    address constant MPX = 0xDd257d090FA0f9ffB496b790844418593e969ba6;
    address constant BAY = 0xa9D3b1408353d05064d47DAF0Dc98E104eb9c98A;
    address constant FGHST = 0x13757D72FAc994F9690045150d60929D64575843; 
    address constant LQDR = 0x06917EFCE692CAD37A77a50B9BEEF6f4Cdd36422;
    address constant TAROT = 0x5F21E3cA21fc0C33cfA5FB33fc7031f61e34D256;
    address constant GRAIN = 0xf2671D5c19C479Cd68b1FE6d2f3A1e0CC7Fe4Ad4;
    address constant ETHOS =  0xf2671D5c19C479Cd68b1FE6d2f3A1e0CC7Fe4Ad4;

    address constant MintTankAddy = 0x14Dc007573Ac5dCC94410bc29DCBb4923e54C69d;
    uint256 constant FULL_LOCK = 52 * 7 * 86400;
    address constant MSIG = 0x88Dec6df03C2C111Efd4ad89Cef2c0347034AFC0;


    function run () external {
        uint256 votePrivateKey = vm.envUint("VOTE_PRIVATE_KEY");
        vm.startBroadcast(votePrivateKey);

            MintTank minttank = MintTank(MintTankAddy);

            minttank.mintFor(2099 * 1e18, FULL_LOCK, DUES);
            minttank.mintFor(2002 * 1e18, FULL_LOCK, MPX);
            minttank.mintFor(1251 * 1e18, FULL_LOCK, BAY);
            minttank.mintFor(1232 * 1e18, FULL_LOCK, FGHST);
            minttank.mintFor(1057 * 1e18, FULL_LOCK, LQDR);
            minttank.mintFor(257 * 1e18, FULL_LOCK, TAROT);
            minttank.mintFor(464 * 1e18, FULL_LOCK, GRAIN);
            minttank.mintFor(726 * 1e18, FULL_LOCK, ETHOS);

            // minttank.transferOwnership(MSIG);


        vm.stopBroadcast();

    } 
}

// forge script script/Rebater.s.sol:Rebater --rpc-url https://rpc.ftm.tools  -vvvv
// forge script script/Rebater.s.sol:Rebater --rpc-url https://fantom.blockpi.network/v1/rpc/public -vvvv

