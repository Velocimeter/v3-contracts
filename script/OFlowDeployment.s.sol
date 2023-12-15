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
        0x86f50BeA072E80ff6ceB1135A39459BB2Cb626C3;
    address private constant DEPLOYER =
        0x86f50BeA072E80ff6ceB1135A39459BB2Cb626C3;

    // TODO: Fill the address
    address private constant WETH = 0x5806E416dA447b267cEA759358cF22Cc41FAE80F;
    address private constant NEW_FLOW = 0x53Fd17012047E44f44F9C7A29196801A8fdb6f23;
    address private constant NEW_PAIR_FACTORY = 0x877031892Ed5F77EBf1BfED84CF890684ce1d1C1;
    address private constant NEW_GAUGE_FACTORY = 0xf171958e893EE4E809Cf2Ed0D221666019A135D7;
    address private constant NEW_VOTER = 0x299e0fab05B87B888A5905c9Cdf820A73c9A2954;
    address private constant NEW_VOTING_ESCROW = 0xF7DD6973618C4ED5bf425F898E174e30c2c139eC;
    address payable private constant NEW_ROUTER = payable(0xe7123FddacD3Ac5D672292E9abAB910D2957ff80);
    address private constant NEW_MINTER = 0x6b46cc017DeC9ECa70b5750a03748947ECa71C12;

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
            "Option to buy BeraVM", // name
            "oBeraVM", // symbol
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
