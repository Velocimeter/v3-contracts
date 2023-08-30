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
    address constant pujimak	=	0x3c2d6d7144241f1f1203c29c124585e55b58975e;
    address constant jamesDigital = 0xe8306d0cba02c1f5a23b38dc3d0f4d6c5fa7a092;
    address constant Flowers = 0xc438e5d32f9381b59072b9a0c730cbac41575a4e;
    address constant chip = 0xfb1329fc9e6b07e684cec845da7f6f3aadc8e7b4;
    address constant wig = 0x5e552e0a1f107b225116b525f0fbfe887d332068;


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

            minttank.mintFor(2747 * 1e18, FULL_LOCK, DEUS);
            minttank.mintFor(2256 * 1e18, FULL_LOCK, MPX);
            minttank.mintFor(943 * 1e18, FULL_LOCK, LQDR);
            minttank.mintFor(672 * 1e18, FULL_LOCK, SCREAM);
            minttank.mintFor(637 * 1e18, FULL_LOCK, TAROT);
            minttank.mintFor(515 * 1e18, FULL_LOCK, COMB);
            minttank.mintFor(441 * 1e18, FULL_LOCK, FBOMB);
            minttank.mintFor(245 * 1e18, FULL_LOCK, ETHOS);
            minttank.mintFor(126 * 1e18, FULL_LOCK, FRAX);
            minttank.mintFor(170 * 1e18, FULL_LOCK, XEX);
            minttank.mintFor(145 * 1e18, FULL_LOCK, BAY);

        }

        function mintForCoorApe() private {
            MintTank minttank = MintTank(MintTankAddy);

            minttank.mintFor(	1966	*1e18, FULL_LOCK,	Panxcake			);
            minttank.mintFor(	2161	*1e18, FULL_LOCK,	h1kupz			);
            minttank.mintFor(	1523	*1e18, FULL_LOCK,	Zozzle			);
            minttank.mintFor(	3989	*1e18, FULL_LOCK,	MasserEffect			);
            minttank.mintFor(	1016	*1e18, FULL_LOCK,	Strawberryking			);
            minttank.mintFor(	2937	*1e18, FULL_LOCK,	shatterproof			);
            minttank.mintFor(	2691	*1e18, FULL_LOCK,	AdalheidisUwu			);
            minttank.mintFor(	973	*1e18, FULL_LOCK,	pujimak			);
            minttank.mintFor(	784	*1e18, FULL_LOCK,	wig			);
            minttank.mintFor(	674	*1e18, FULL_LOCK,	jamesDigital			);
            minttank.mintFor(	550	*1e18, FULL_LOCK,	Flowers			);
            minttank.mintFor(	516	*1e18, FULL_LOCK,	chip			);
        }

    } 
}

// forge script script/Rebater.s.sol:Rebater --rpc-url https://rpc.ftm.tools  -vvvv
// forge script script/Rebater.s.sol:Rebater --rpc-url https://fantom.blockpi.network/v1/rpc/public -vvvv

