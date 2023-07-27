// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {IFlow} from "../contracts/interfaces/IFlow.sol";
import {FlowConvertor} from "../contracts/FlowConvertor.sol";

contract FlowConvertorDeployment is Script {
    address private constant TEAM_MULTI_SIG =
        0x13eeB8EdfF60BbCcB24Ec7Dd5668aa246525Dc51;
    // TODO: Fill the address
    address private constant FLOW_V2 =
        0x78e489523291581205Ea3fA16a69689EcA79757A;
    address private constant FLOW_V3 = 0xbAD86785eB08fe9d0948B7D9d24523000A177cD0;
    address private constant VOTING_ESCROW_V2 = 0x8E003242406FBa53619769F31606ef2Ed8A65C00;
    address private constant VOTING_ESCROW_V3 = 0xA1B589FB7e04d19CEC391834131158f7F9d2D168;
    uint256 private constant MAX_NFT_ID_TO_CLAIM = 1227;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        uint256[] memory blacklistedNftIds = new uint256[](17);
        blacklistedNftIds[0] = 37;
        blacklistedNftIds[1] = 43; 
        blacklistedNftIds[2] = 44; 
        blacklistedNftIds[3] = 45; 
        blacklistedNftIds[4] = 46; 
        blacklistedNftIds[5] = 57; 
        blacklistedNftIds[6] = 72; 
        blacklistedNftIds[7] = 77; 
        blacklistedNftIds[8] = 78; 
        blacklistedNftIds[9] = 82; 
        blacklistedNftIds[10] = 83; 
        blacklistedNftIds[11] = 92; 
        blacklistedNftIds[12] = 71; 
        blacklistedNftIds[13] = 100;
        blacklistedNftIds[14] = 76; 
        blacklistedNftIds[15] = 79; 
        blacklistedNftIds[16] = 81; 

        vm.startBroadcast(deployerPrivateKey);

        FlowConvertor flowConvertor = new FlowConvertor({
            _v1: FLOW_V2,
            _v2: FLOW_V3,
            _votingEscrowV1: VOTING_ESCROW_V2,
            _votingEscrowV2: VOTING_ESCROW_V3,
            _maxNftId: MAX_NFT_ID_TO_CLAIM,
            _blacklistedNftIds: blacklistedNftIds
        });

        flowConvertor.transferOwnership(TEAM_MULTI_SIG);

        vm.stopBroadcast();
    }
}
