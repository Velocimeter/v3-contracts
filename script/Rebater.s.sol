// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

// Scripting tool
import "forge-std/console2.sol";
import {Script} from "../lib/forge-std/src/Script.sol";
import {MintTank} from "../contracts/MintTank.sol";
import {Voter} from "../contracts/Voter.sol";

contract Rebater is Script { 

    // partner destinations
    address constant MPX = 0xDd257d090FA0f9ffB496b790844418593e969ba6;
    address constant DEUS = 0x83B285E802D76055169B1C5e3bF21702B85b89Cb;
    address constant LQDR = 0x06917EFCE692CAD37A77a50B9BEEF6f4Cdd36422;
    address constant TAROT = 0x5F21E3cA21fc0C33cfA5FB33fc7031f61e34D256;
    address constant SCREAM = 0x89955a99552F11487FFdc054a6875DF9446B2902;
    address constant BAY = 0xa9D3b1408353d05064d47DAF0Dc98E104eb9c98A;
    address constant ETHOS =  0xf2671D5c19C479Cd68b1FE6d2f3A1e0CC7Fe4Ad4;
    address constant FUCKMULTI = 0x13483374E385ACbEB8285954D0A1c61b0b9a2f62;
    address constant GRAIN = 0xf2671D5c19C479Cd68b1FE6d2f3A1e0CC7Fe4Ad4;
    address constant FRAX = 0xE838c61635dd1D41952c68E47159329443283d90;
    address constant XEX = 0x89DdBAcc77A14D505101CE669a683e1B01781701;
    address constant BLOTR = 0x58328aE00df6017Dbe83c5F59CaB96430E6926Ae; 

    address constant FGHST = 0x13757D72FAc994F9690045150d60929D64575843; 

    address constant MintTankAddy = 0x14Dc007573Ac5dCC94410bc29DCBb4923e54C69d;
    uint256 constant FULL_LOCK = 52 * 7 * 86400;
    address constant MSIG = 0x88Dec6df03C2C111Efd4ad89Cef2c0347034AFC0;
    address constant PVOP = 0xcC06464C7bbCF81417c08563dA2E1847c22b703a;


    function run () external {
        uint256 votePrivateKey = vm.envUint("VOTE_PRIVATE_KEY");
        vm.startBroadcast(votePrivateKey);

            MintTank minttank = MintTank(MintTankAddy);

            minttank.mintFor(60000 * 1e18, FULL_LOCK, MPX);
            minttank.mintFor(60000 * 1e18, FULL_LOCK, DEUS);
            minttank.mintFor(60000 * 1e18, FULL_LOCK, LQDR);
            minttank.mintFor(60000 * 1e18, FULL_LOCK, SCREAM);

            // minttank.mintFor(1661 * 1e18, FULL_LOCK, TAROT);
            // minttank.mintFor(961 * 1e18, FULL_LOCK, BAY);
            // minttank.mintFor(771 * 1e18, FULL_LOCK, ETHOS);
            // minttank.mintFor(193 * 1e18, FULL_LOCK, FUCKMULTI);
            // minttank.mintFor(504 * 1e18, FULL_LOCK, GRAIN);
            // minttank.mintFor(503 * 1e18, FULL_LOCK, FRAX);
            // minttank.mintFor(67 * 1e18, FULL_LOCK, XEX);
            // minttank.mintFor(215 * 1e18, FULL_LOCK, BLOTR);

            // minttank.transferOwnership(MSIG);


        vm.stopBroadcast();

    } 
}

// forge script script/Rebater.s.sol:Rebater --rpc-url https://rpc.ftm.tools  -vvvv
// forge script script/Rebater.s.sol:Rebater --rpc-url https://fantom.blockpi.network/v1/rpc/public -vvvv

