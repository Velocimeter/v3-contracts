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
    address constant OVERNIGHT = 0x784Cf4b62655486B405Eb76731885CC9ed56f42f;
    address constant SMOOTH = 0x56bE76bD656813fd5ac5A65ebDbE28a1FD56deB3;

    address constant MintTankAddy = 0x9B5EC2ddCb1BeeBEA5FFe94e6449b4eC56294cBa;
    uint256 constant FULL_LOCK = 52 * 7 * 86400;
    address constant MSIG = 0xfA89A4C7F79Dc4111c116a0f01061F4a7D9fAb73;

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

            minttank.mintFor(126 * 1e18, FULL_LOCK, MPX);
            minttank.mintFor(334 * 1e18, FULL_LOCK, OVERNIGHT);
            minttank.mintFor(45 * 1e18, FULL_LOCK, SMOOTH);

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

