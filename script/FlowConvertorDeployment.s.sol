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
    address private constant FLOW_V3 = address(0);
    address private constant VOTING_ESCROW_V2 = 0x8E003242406FBa53619769F31606ef2Ed8A65C00;
    address private constant VOTING_ESCROW_V3 = address(0);
    uint256 private constant FIFTY_MILLION = 50e24; // 50e24 == 50e6 (50m) ** 1e18 (decimals)

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        FlowConvertor flowConvertor = new FlowConvertor({
            _v1: FLOW_V2,
            _v2: FLOW_V3,
            _votingEscrowV1: VOTING_ESCROW_V2,
            _votingEscrowV2: VOTING_ESCROW_V3
        });

        flowConvertor.transferOwnership(TEAM_MULTI_SIG);

        IFlow(FLOW_V3).transfer(address(flowConvertor), FIFTY_MILLION);

        vm.stopBroadcast();
    }
}
