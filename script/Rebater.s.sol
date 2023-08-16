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
    address constant FBOMB = 0x28aa4F9ffe21365473B64C161b566C3CdeAD0108;
    address constant COMB = 0x092cC0BF1b4b0947962d6aC96d0Bb8bC21533406;
    address constant FGHST = 0x13757D72FAc994F9690045150d60929D64575843; 
    address constant SCANTO = 0x58328aE00df6017Dbe83c5F59CaB96430E6926Ae; 

    address constant MintTankAddy = 0x14Dc007573Ac5dCC94410bc29DCBb4923e54C69d;
    uint256 constant FULL_LOCK = 52 * 7 * 86400;
    address constant MSIG = 0x88Dec6df03C2C111Efd4ad89Cef2c0347034AFC0;
    address constant PVOP = 0xcC06464C7bbCF81417c08563dA2E1847c22b703a;

    // contribs addresses
    address constant Panxcake	=	0x620675E061ab980EDf7dE559211E4aF5dec41210;
    address constant h1kupz	=	0x714C8A1DB40eedc9240AF30bB25D5440796536aa;
    address constant Zozzle	=	0x5ca642d0138f8fa36f4ec6311190825392246AdA;
    address constant MasserEffect	=	0x486A0e4897018B286b7b2bfe63476AaD1437A040;
    address constant Strawberryking	=	0xC9eebecb1d0AfF4fb2B9978516E075A33639892C;
    address constant shatterproof	=	0x7c22953Bf2245A8298baf26D586Bd4b08a87caaa;
    address constant AdalheidisUwu	=	0x787B25B31BC3756dACA7ED27BeA723D6f43D0f99;
    address constant OxPonci	=	0x5fA275BA9F04BDC906084478Dbf41CBE29388C5d;


    function run () external {
        uint256 votePrivateKey = vm.envUint("VOTE_PRIVATE_KEY");
        vm.startBroadcast(votePrivateKey);


            // CHOSE ONE
            mintForRebate();
            // mintForCoorApe();

            // minttank.transferOwnership(MSIG);

        vm.stopBroadcast();

        function mintForRebate() private {
            MintTank minttank = MintTank(MintTankAddy);

            minttank.mintFor(3041 * 1e18, FULL_LOCK, MPX);
            minttank.mintFor(2041 * 1e18, FULL_LOCK, DEUS);
            minttank.mintFor(667 * 1e18, FULL_LOCK, LQDR);
            minttank.mintFor(1434 * 1e18, FULL_LOCK, SCREAM);
            minttank.mintFor(223 * 1e18, FULL_LOCK, BAY);
            minttank.mintFor(825 * 1e18, FULL_LOCK, TAROT);
            minttank.mintFor(300 * 1e18, FULL_LOCK, ETHOS);
            // minttank.mintFor(149 * 1e18, FULL_LOCK, FUCKMULTI);
            // minttank.mintFor(83 * 1e18, FULL_LOCK, XEX);
            minttank.mintFor(145 * 1e18, FULL_LOCK, FRAX);
            minttank.mintFor(221 * 1e18, FULL_LOCK, GRAIN);
            minttank.mintFor(1888 * 1e18, FULL_LOCK, FBOMB);
            minttank.mintFor(231 * 1e18, FULL_LOCK, COMB);
            minttank.mintFor(253 * 1e18, FULL_LOCK, SCANTO);

        }

        function mintForCoorApe() private {
            MintTank minttank = MintTank(MintTankAddy);

            minttank.mintFor(	3123	*1e18, FULL_LOCK,	Panxcake			);
            minttank.mintFor(	2199	*1e18, FULL_LOCK,	h1kupz			);
            minttank.mintFor(	1952	*1e18, FULL_LOCK,	Zozzle			);
            minttank.mintFor(	1849	*1e18, FULL_LOCK,	MasserEffect			);
            minttank.mintFor(	1767	*1e18, FULL_LOCK,	Strawberryking			);
            minttank.mintFor(	1500	*1e18, FULL_LOCK,	shatterproof			);
            minttank.mintFor(	1459	*1e18, FULL_LOCK,	AdalheidisUwu			);
            minttank.mintFor(	1151	*1e18, FULL_LOCK,	OxPonci			);
        }

    } 
}

// forge script script/Rebater.s.sol:Rebater --rpc-url https://rpc.ftm.tools  -vvvv
// forge script script/Rebater.s.sol:Rebater --rpc-url https://fantom.blockpi.network/v1/rpc/public -vvvv

