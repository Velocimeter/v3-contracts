// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {IFlow} from "../contracts/interfaces/IFlow.sol";
import {IPair} from "../contracts/interfaces/IPair.sol";
import {Flow} from "../contracts/Flow.sol";
import {OptionTokenV3} from "../contracts/OptionTokenV3.sol";
import {GaugeFactoryV4} from "../contracts/factories/GaugeFactoryV4.sol";
import {BribeFactory} from "../contracts/factories/BribeFactory.sol";
import {PairFactory} from "../contracts/factories/PairFactory.sol";
import {Router} from "../contracts/Router.sol";
import {VotingEscrow} from "../contracts/VotingEscrow.sol";
import {Voter} from "../contracts/Voter.sol";

contract OFlowDeployment is Script {
    address private constant TEAM_MULTI_SIG =
        0xEe35accF2F94c403B9fFA507D796d1D1994BD870;
    address private constant DEPLOYER =
        0xEe35accF2F94c403B9fFA507D796d1D1994BD870;

    // TODO: Fill the address
    address private constant WETH = 0x5300000000000000000000000000000000000004;
    address private constant NEW_FLOW = 0x5fC02571D53A9B71cE8F5063307367d6fD2caf85;
    address private constant NEW_PAIR_FACTORY = 0x83A7d44861f28940D9c5Fa22ce1b91CFb66dAb6B;
    address private constant NEW_GAUGE_FACTORY = 0xeE807d924B15c84a8dE3490a5b6273f43dd0Fc56;
    address private constant NEW_VOTER = 0xE9B9A807C465904612B72a130E2D9662DDE230FB;
    address private constant NEW_VOTING_ESCROW = 0x917383C52e4357965e99e411a39cbD240f4C9061;
    address payable private constant NEW_ROUTER = payable(0xda88794Bd073de116a842e5a4add523Cd76C9E73);
    address private constant NEW_MINTER = 0x4F298C2aE633113Ae9DA926a5794f8163081F500;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Flow(NEW_FLOW).approve(NEW_ROUTER, 1e18);
        Router(NEW_ROUTER).addLiquidityETH{value: 1e18}(
            NEW_FLOW,
            false,
            1e18,
            0, // Conversion ratio
            0,
            DEPLOYER,
            block.timestamp + 1000
        );

        address pair = PairFactory(NEW_PAIR_FACTORY).getPair(
            NEW_FLOW,
            WETH,
            false
        );

        // Option to buy Flow
        OptionTokenV3 oFlow = new OptionTokenV3(
            "Option to buy GVM", // name
            "oGVM", // symbol
            TEAM_MULTI_SIG, // admin
            WETH, // payment token
            NEW_FLOW, // underlying token
            IPair(pair), // pair
            NEW_GAUGE_FACTORY, // gauge factory,
            TEAM_MULTI_SIG,
            NEW_VOTER,
            NEW_VOTING_ESCROW,
            NEW_ROUTER
        );

        GaugeFactoryV4(NEW_GAUGE_FACTORY).setOFlow(address(oFlow));

        // Transfer gaugefactory ownership to MSIG (team)
        GaugeFactoryV4(NEW_GAUGE_FACTORY).transferOwnership(TEAM_MULTI_SIG);

        address[] memory whitelistedTokens = new address[](3);
        whitelistedTokens[0] = NEW_FLOW;
        whitelistedTokens[1] = WETH;
        whitelistedTokens[2] = address(oFlow);
        Voter(NEW_VOTER).initialize(whitelistedTokens, NEW_MINTER);

        // Create gauge for flowWftm pair
        Voter(NEW_VOTER).createGauge(pair, 0);

        // Update gauge in Option Token contract
        oFlow.updateGauge();

        vm.stopBroadcast();
    }
}
