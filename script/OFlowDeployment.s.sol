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
        0x5b86A94b14Df577cCf2eA19d4f28560161B77715;
    address private constant DEPLOYER =
        0x4b1B2F1438C7beD2D3e5eA1Da5b8d14BE8c06fF2;

    // TODO: Fill the address
    address private constant WETH = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
    address private constant NEW_FLOW = 0xE2244F3c62F4b313Cf9C5371c19E9ec9c89b8641;
    address private constant NEW_PAIR_FACTORY = 0x6738fF9bCE566b4F80bB604e18b9bA3B0daE60cA;
    address private constant NEW_GAUGE_FACTORY = 0x0f789dCcf70C4609BbC05491F0fF1c974037DC60;
    address private constant NEW_VOTER = 0x34bAa0b40dc2Bd98c9fdDd5121Ba1bB855870338;
    address private constant NEW_VOTING_ESCROW = 0x762D6b449fFaC41DFDA9C9f3a22004F496cE7c80;
    address payable private constant NEW_ROUTER = payable(0x91aC12C15B8e9ac90d1585c7A586555d167cAb5B);
    address private constant NEW_MINTER = 0x68793d678B58a12166d6b1B604E5a148D963d3B4;

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
