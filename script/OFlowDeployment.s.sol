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
        0x0a2553153801Cd4F652e80B14B9824A8EE8538E2;
    address private constant DEPLOYER =
        0x0a2553153801Cd4F652e80B14B9824A8EE8538E2;

    // TODO: Fill the address
    address private constant WETH = 0x5300000000000000000000000000000000000004;
    address private constant NEW_FLOW = 0x1AEe2203fd88ab93784Ea5F37b654d72641167d6;
    address private constant NEW_PAIR_FACTORY = 0x315111782a6Bf07e405709154d9358c8f8AF457b;
    address private constant NEW_GAUGE_FACTORY = 0x3bF261E0aB9053c33bA3fd2d8e8f64C86EbF10fD;
    address private constant NEW_VOTER = 0x6E7cfd2A3fFa6264A5a2f237dD4a5cc1a35025D6;
    address private constant NEW_VOTING_ESCROW = 0x21871EB8D9CbD8C2B7a6FB044d91491799A07b03;
    address payable private constant NEW_ROUTER = payable(0x31227ce6a35eF8323695a3A682210B81058Acd87);
    address private constant NEW_MINTER = 0xc0D5Ec393CDF88445bf01364c5E3B2F44e75c1B3;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Flow(NEW_FLOW).approve(NEW_ROUTER, 1e18);
        Router(NEW_ROUTER).addLiquidityETH{value: 5e14}(
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
            "Option to buy SVM", // name
            "oSVM", // symbol
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
