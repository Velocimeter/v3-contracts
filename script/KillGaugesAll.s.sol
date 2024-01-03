// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import "forge-std/console2.sol";
import {Script} from "../lib/forge-std/src/Script.sol";
import {Voter} from "../contracts/Voter.sol";
import {IGauge} from "../contracts/interfaces/IGauge.sol";
import {IERC20} from "../contracts/interfaces/IERC20.sol";


contract KillGaugesAll is Script { 

//kill
address constant	A1	=	0xe16d2d37774b18A430f468a76Db2F706d2ee5CBa	; //	vAMM-WETH/fBOMB
address constant	A2	=	0x0256fa68db7E6d8A2BeC385c443516ecEF5e6776	; //	vAMM-gCEAZOR/USD+
address constant	A3	=	0xa2358BD62fdeca93d828Ad76c4C743eF5DaB19c8	; //	vAMM-CEAZOR/WETH
address constant	A4	=	0x34AebC107C754C3194C585Fb885336c985B080DD	; //	sAMM-USDbC/DISE
address constant	A5	=	0x34C13687F5a9A19768A0B7719fc075c13BE9207A	; //	vAMM-USDC/TAROT
address constant	A6	=	0x1aF771584e1F296ac4855728A08FAaE5C1EfD979	; //	vAMM-WETH/BASIN
address constant	A7	=	0x5Be56eCF5768534FD0AA73411945EB40B05a94a6	; //	vAMM-CYI/WETH
address constant	A8	=	0xD9875fBe2A706f9Fed68F066D7420D63FDC5eD76	; //	sAMM-USD+/USDbC
address constant	A9	=	0x5014A862eD4C39fbD3668745fa8b9915cde44B8c	; //	sAMM-BAI/USDbC
address constant	A10	=	0x5806d896692F5C30de281ab5EB0485d530CaC408	; //	vAMM-WETH/gSIS
address constant	A11	=	0xea53AeBa4a6E5c1b7c3d372dd14Dde0C09Aa281b	; //	sAMM-BAI/USDC
address constant	A12	=	0xc246B6295dB606B8De563F9664265d38B766E76e	; //	vAMM-SIS/WETH
address constant	A13	=	0xeE339a530fe0Cb41784fbd3935ECEB5D9594a388	; //	vAMM-WETH/USD+
address constant	A14	=	0x32d077840235aB8Fb340fdDc0Ecf29971a576235	; //	sAMM-DAI+/USDbC
address constant	A15	=	0x0dAf00A383F8897553aC1d03F4445B15AfA1dcb9	; //	sAMM-DAI+/USD+
address constant	A16	=	0x855f4e9A2b802F44Ed45e0508e715069c1c12ffa	; //	vAMM-YFX/USDbC
address constant	A17	=	0xb2E25C8b109A52717748399E65ef6fd33445De18	; //	vAMM-WETH/UNIDX
address constant	A18	=	0x2008cef3b484cdbE827a6aE3F215D96160aFd2F3	; //	vAMM-MAG/WETH
address constant	A19	=	0x1673A3057105c6eE07B5dE832803be1008881A25	; //	vAMM-TV/WETH
					
//blacklist					
address constant	A20	=	0x74ccbe53F77b08632ce0CB91D3A545bF6B8E0979	; //	fbomb
address constant	A21	=	0x1E6f361eB7D166D9e600617CeDeCe69eC645B610	; //	gCeazor
address constant	A22	=	0xB79DD08EA68A908A97220C76d19A6aA9cBDE4376	; //	USD+
address constant	A23	=	0x19761755a6cb972c20C9684131cCF46a3f0C0b66	; //	CEAZOR
address constant	A24	=	0xdcE2514F8949dD5B3871A44B6495A4c4b5B9459a	; //	DISE
address constant	A25	=	0xF544251D25f3d243A36B07e7E7962a678f952691	; //	TAROT
address constant	A26	=	0x4788de271F50EA6f5D5D2a5072B8D3C61d650326	; //	BASIN
address constant	A27	=	0x2fEB15b8185053092a5f6D77B99FC05082A499c6	; //	CYI
address constant	A28	=	0x5c185329BC7720AebD804357043121D26036D1B3	; //	BAI
address constant	A29	=	0xac8DA2e2a1A114AAfe50c774c588DCD93a028fc8	; //	gSIS
address constant	A30	=	0x2259ba575F7C66cF10d59a1Fe2F7BA77C5685770	; //	BAI
address constant	A31	=	0x0868D3aecd29fE4e4f4490B4D3D0e937C6eF07EC	; //	SIS
address constant	A32	=	0x65a2508C429a6078a7BC2f7dF81aB575BD9D9275	; //	DAI+
address constant	A33	=	0x8901cB2e82CC95c01e42206F8d1F417FE53e7Af0	; //	YFX
address constant	A34	=	0x6B4712AE9797C199edd44F897cA09BC57628a1CF	; //	UNDX
address constant	A35	=	0x2DC1cDa9186a4993bD36dE60D08787c0C382BEAD	; //	MAG
address constant	A36	=	0x02e47D464c3bB564964fce162e6c8F38eA744f5a	; //	TV
					
//pause					
address constant	A37	=	0xEF36dd99EEb4654fD230e9913755Af78edB3D871	; //	vAMM-BULLRUN/GG
address constant	A38	=	0x8D074B48C5B6180FE332A621e909C3B241d85D56	; //	vAMM-BLAZE/WETH
address constant	A39	=	0xfEf5ce171F44b269D9425E7701ba1489B10fA7d1	; //	vAMM-wBLT/DEUS
address constant	A40	=	0x02a615Ce9450d65A586aBA65e0FcE05dc446e2d2	; //	vAMM-gLEVI/USD+
address constant	A41	=	0xaE81ADcf1F3Ab48aFe21bEcf78EE3C5127a53935	; //	vAMM-GG/USDbC
address constant	A42	=	0x0DD70199Af12F00beD2e0DF0dE1305e3A95C0fFc	; //	sAMM-MIM/USDbC
address constant	A43	=	0xeFC6C5335eb31a21BACF77E5B7D1691144a21143	; //	vAMM-WETH/DIP
address constant	A44	=	0x5b767F3BB3129e067502EAFeB0DC5A4C021755dd	; //	vAMM-BALD/WETH
address constant	A45	=	0xB5e6163a8D4398F98800B173813C24F342A518C4	; //	vAMM-WETH/DAI
address constant	A46	=	0x72e4b91EcDAF40B0113995C45Ab078ce98498255	; //	vAMM-WETH/ICE
address constant	A47	=	0xDCd7EB9f982BAB2c86a42fEA8427194497022F67	; //	vAMM-WETH/MIM
address constant	A48	=	0x8Cdce48b3FB83280440a55d6a45d69A65B9011f5	; //	vAMM-WETH/MILADY
address constant	A49	=	0x28f91301C10DB7C0388E0394B53c98cda8bf1ca2	; //	vAMM-WETH/oBVM
address constant	A50	=	0xF5b4bAb70579229733bec874856C203c1b920Eb1	; //	vAMM-WETH/WF
address constant	A51	=	0xf9bcD2E266396e8cbEa54fE6DAc32F7013E60307	; //	vAMM-WETH/ADAM
address constant	A52	=	0x051847E477C44845d0b5Ce516EdE4406C4E75104	; //	vAMM-WETH/OGRE
address constant	A53	=	0x717FE1B25dF64675aDC1fe274409729097382a37	; //	sAMM-MAI/USDbC
address constant	A54	=	0x500Ce1cBb5327Ec212b2a501F6438af0290C7485	; //	sAMM-USDC/USDbC
address constant	A55	=	0xBd745d5e3a4125a63c72f01C49A3E716a1B3FA33	; //	sAMM-ERN/axlUSDC
address constant	A56	=	0xf655674D798A84797Cb2E4d789780BC52B73628A	; //	vAMM-WETH/Dbase
address constant	A57	=	0xe14862d7db30b112385191Ad206A5Fc8be176b60	; //	vAMM-WETH/GG
address constant	A58	=	0xab87751d3bD3099a2d2654ECF73B8373f48F4eEd	; //	vAMM-WETH/TCF
address constant	A59	=	0x349CdfbFE088F48645Fe10E360247378735C31C9	; //	vAMM-WETH/Racer
address constant	A60	=	0xB71c8C941ccCaf488501dBbb8d63a5268B0E3584	; //	vAMM-WETH/PIX
address constant	A61	=	0xe9ac960800918D6F9826EAf95850F118374b967F	; //	vAMM-JEFF/WETH
address constant	A62	=	0x0e949D4384d79D97292Ad6283380e6b2e384C69A	; //	vAMM-WETH/CRUMBS
address constant	A63	=	0xe7F6cE6f06039C0d9B13Ed78A22eDE0a5F7280E7	; //	sAMM-ERN/USD+
address constant	A64	=	0x87460346EA1C6B67d26C6286066823AB0c0287Cc	; //	vAMM-WETH/LEVI
address constant	A65	=	0x297f1c8b20A208E72d0088C19E9A6faCBCfDFd64	; //	vAMM-agEUR/USDbC
address constant	A66	=	0x6D4eD5fc3796F625a0E06b02811833714f7C1f37	; //	vAMM-WETH/MPX
address constant	A67	=	0xfF7f27FDc80E6187b7B7a5b2e60A195d2302D29e	; //	sAMM-bTiUSD/USDbC
address constant	A68	=	0x0764BC8cc585F2864b423278398cD023A5490A85	; //	vAMM-bTiTi/USDbC
address constant	A69	=	0x72bF48F90855Dfd95AB93FAbb18664c9364712BD	; //	vAMM-WETH/scott
address constant	A70	=	0xc89AFAc1b61D4EF0Fa43353746c313Ffa3A97E96	; //	vAMM-SURV/WETH

address constant safe = 0xfA89A4C7F79Dc4111c116a0f01061F4a7D9fAb73;

mapping(uint256 => address) tokens;
mapping(uint256 => address) gauges;
mapping(uint256 => address) pGauges;

function makeTokens() internal {
    tokens[1] = A20;
    tokens[2] = A21;
    tokens[3] = A22;
    tokens[4] = A23;
    tokens[5] = A24;
    tokens[6] = A25;
    tokens[7] = A26;
    tokens[8] = A27;
    tokens[9] = A28;
    tokens[10] = A29;
    tokens[11] = A30;
    tokens[12] = A31;
    tokens[13] = A32;
    tokens[14] = A33;
    tokens[15] = A34;
    tokens[16] = A35;
    tokens[17] = A36;
}

function makeGauges() internal {
	gauges[	1	]=	A1	;
	gauges[	2	]=	A2	;
	gauges[	3	]=	A3	;
	gauges[	4	]=	A4	;
	gauges[	5	]=	A5	;
	gauges[	6	]=	A6	;
	gauges[	7	]=	A7	;
	gauges[	8	]=	A8	;
	gauges[	9	]=	A9	;
	gauges[	10	]=	A10	;
	gauges[	11	]=	A11	;
	gauges[	12	]=	A12	;
	gauges[	13	]=	A13	;
	gauges[	14	]=	A14	;
	gauges[	15	]=	A15	;
	gauges[	16	]=	A16	;
	gauges[	17	]=	A17	;
	gauges[	18	]=	A18	;
	gauges[	19	]=	A19	;

}

function makePGauges() internal {
	pGauges[	1	]=	A37	;
	pGauges[	2	]=	A38	;
	pGauges[	3	]=	A39	;
	pGauges[	4	]=	A40	;
	pGauges[	5	]=	A41	;
	pGauges[	6	]=	A42	;
	pGauges[	7	]=	A43	;
	pGauges[	8	]=	A44	;
	pGauges[	9	]=	A45	;
	pGauges[	10	]=	A46	;
	pGauges[	11	]=	A47	;
	pGauges[	12	]=	A48	;
	pGauges[	13	]=	A49	;
	pGauges[	14	]=	A50	;
	pGauges[	15	]=	A51	;
	pGauges[	16	]=	A52	;
	pGauges[	17	]=	A53	;
	pGauges[	18	]=	A54	;
	pGauges[	19	]=	A55	;
	pGauges[	20	]=	A56	;
	pGauges[	21	]=	A57	;
	pGauges[	22	]=	A58	;
	pGauges[	23	]=	A59	;
	pGauges[	24	]=	A60	;
	pGauges[	25	]=	A61	;
	pGauges[	26	]=	A62	;
	pGauges[	27	]=	A63	;
	pGauges[	28	]=	A64	;
	pGauges[	29	]=	A65	;
	pGauges[	30	]=	A66	;
	pGauges[	31	]=	A67	;
	pGauges[	32	]=	A68	;
	pGauges[	33	]=	A69	;
	pGauges[	34	]=	A70	;
    pGauges[	35	]=	A1	;
	pGauges[	36	]=	A2	;
	pGauges[	37	]=	A3	;
	pGauges[	38	]=	A4	;
	pGauges[	39	]=	A5	;
	pGauges[	40	]=	A6	;
	pGauges[	41	]=	A7	;
	pGauges[	42	]=	A8	;
	pGauges[	43	]=	A9	;
	pGauges[	44	]=	A10	;
	pGauges[	45	]=	A11	;
	pGauges[	46	]=	A12	;
	pGauges[	47	]=	A13	;
	pGauges[	48	]=	A14	;
	pGauges[	49	]=	A15	;
	pGauges[	50	]=	A16	;
	pGauges[	51	]=	A17	;
	pGauges[	52	]=	A18	;
	pGauges[	53	]=	A19	;
}

function run() external {
        uint256 PrivateKey = vm.envUint("VOTE_PRIVATE_KEY");
        vm.startBroadcast(PrivateKey);
        Voter voter = Voter(0xab9B68c9e53c94D7c0949FB909E80e4a29F9134A);


        makeTokens();
        // makeGauges();
        makePGauges();

        // uint256 current = 1;
        // uint256 max = 19;
        string memory symbol;
        
        // while (current <= max){
        //     address addy = gauges[current];
        //     address pair = IGauge(addy).stake();
        //     symbol = IERC20(pair).symbol();
        //     console2.log("kill gauge for", symbol);
        //     // _killGauges(addy);
        //     current++;
        // }

        uint256 currentP = 1;
        uint256 maxPGauge = 53;

        while (currentP <= maxPGauge){
            address paddy = pGauges[currentP];
            address ppair = IGauge(paddy).stake();
            symbol = IERC20(ppair).symbol();
            // console2.log("pause", symbol);
            bool isAlive = voter.isAlive(paddy);
            console2.log(symbol, "isAlive", isAlive);
            bool isGauge = voter.isGauge(paddy);
            console2.log(symbol, "isGauge", isGauge);
            // _pauseGauges(paddy);
            currentP++;
        }

        uint256 current = 1;
        uint256 maxtoken = 17;

        while (current <= maxtoken){
            address taddy = tokens[current];
            symbol = IERC20(taddy).symbol();
            bool white = voter.isWhitelisted(taddy);
            if (white == true){
                console2.log(symbol, "is whitelisted");
                console2.log("blacklisted", symbol);
                // _blackTokens(taddy);
            }
            current++;
        }

        // voter.setGovernor(safe);
        

        vm.stopBroadcast();
    }


    function _killGauges(address _gauge) private {
        Voter voter = Voter(0xab9B68c9e53c94D7c0949FB909E80e4a29F9134A);
        
        if (voter.isAlive(_gauge) == true){
            voter.killGaugeTotally(_gauge);
            console2.log(_gauge, "was killed");
            }
    }
    function _pauseGauges(address _gauge) private {
        Voter voter = Voter(0xab9B68c9e53c94D7c0949FB909E80e4a29F9134A);
        
        if (voter.isAlive(_gauge) == true){
            voter.pauseGauge(_gauge);
            console2.log(_gauge, "was paused");
            }
    }
    function _blackTokens(address _token) private {
        Voter voter = Voter(0xab9B68c9e53c94D7c0949FB909E80e4a29F9134A);
        
            voter.blacklist(_token);
            console2.log(_token, "was blacked");
            }
    

    function _isAlive(address _gauge) private view {
        Voter voter = Voter(0xab9B68c9e53c94D7c0949FB909E80e4a29F9134A);
          bool alive = voter.isAlive(_gauge);
          console2.log(_gauge, "is alive?", alive);
        }
}




