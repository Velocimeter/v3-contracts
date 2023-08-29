// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {IFlow} from "../contracts/interfaces/IFlow.sol";
import {IPair} from "../contracts/interfaces/IPair.sol";
import {Flow} from "../contracts/Flow.sol";
import {OptionTokenV3} from "../contracts/OptionTokenV3.sol";
import {GaugeFactoryV3} from "../contracts/factories/GaugeFactoryV3.sol";
import {BribeFactory} from "../contracts/factories/BribeFactory.sol";
import {PairFactory} from "../contracts/factories/PairFactory.sol";
import {Router} from "../contracts/Router.sol";
import {VotingEscrow} from "../contracts/VotingEscrow.sol";
import {Voter} from "../contracts/Voter.sol";

contract OFlowDeployment is Script {
    address private constant TEAM_MULTI_SIG =
        0x651B44Da48fF3c4B5449fDcDB25bc3FA4C5cC905;
    address private constant DEPLOYER =
        0x651B44Da48fF3c4B5449fDcDB25bc3FA4C5cC905;

    // TODO: Fill the address
    address private constant WMNT = 0x2C6db4f138A1336dB50Ab698cA70Cf99a37e1198;
    address private constant NEW_FLOW = 0xEFF6Eb48a48F8E02B29FF7a8536a713C79F41b84;
    address private constant NEW_PAIR_FACTORY = 0x0228B7602b8AB1342dC16f6b700717e74A0E220D;
    address private constant NEW_GAUGE_FACTORY = 0xFd9c8F58cF6E55390eB38Ac19EC1d0a11dE19ac6;
    address private constant NEW_VOTER = 0xf3754804d6aE219945E25dA054cBDc12364154Be;
    address private constant NEW_VOTING_ESCROW = 0x08f76A6E6C1141986c5F958DF2802695A2d08FdF;
    address payable private constant NEW_ROUTER = payable(0xf62e7Fc2096ff1eFF3477069B6763674af6aDc23);
    address private constant NEW_MINTER = 0x6da59902a529279BB6790Ca9f3820b23547C1971;

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
            WMNT,
            false
        );

        // Option to buy Flow
        OptionTokenV3 oFlow = new OptionTokenV3(
            "Option to buy MVM", // name
            "oMVM", // symbol
            TEAM_MULTI_SIG, // admin
            WMNT, // payment token
            NEW_FLOW, // underlying token
            IPair(pair), // pair
            NEW_GAUGE_FACTORY, // gauge factory,
            TEAM_MULTI_SIG,
            NEW_VOTER,
            NEW_VOTING_ESCROW,
            NEW_ROUTER
        );

        GaugeFactoryV3(NEW_GAUGE_FACTORY).setOFlow(address(oFlow));

        // Transfer gaugefactory ownership to MSIG (team)
        GaugeFactoryV3(NEW_GAUGE_FACTORY).transferOwnership(TEAM_MULTI_SIG);

        address[] memory whitelistedTokens = new address[](3);
        whitelistedTokens[0] = NEW_FLOW;
        whitelistedTokens[1] = WMNT;
        whitelistedTokens[2] = address(oFlow);
        Voter(NEW_VOTER).initialize(whitelistedTokens, NEW_MINTER);

        // Create gauge for flowWftm pair
        Voter(NEW_VOTER).createGauge(pair, 0);

        // Update gauge in Option Token contract
        oFlow.updateGauge();

        vm.stopBroadcast();
    }
}
