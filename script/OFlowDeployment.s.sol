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
        0x28b0e8a22eF14d2721C89Db8560fe67167b71313;
    address private constant DEPLOYER =
        0x6E0AFB1912d4Cc8edD87E2672bA32952c6BB85C3;

    // TODO: Fill the address
    address private constant WMNT = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8;
    address private constant NEW_FLOW = 0x861A6Fc736Cbb12ad57477B535B829239c8347d7;
    address private constant NEW_PAIR_FACTORY = 0x99F9a4A96549342546f9DAE5B2738EDDcD43Bf4C;
    address private constant NEW_GAUGE_FACTORY = 0xf19d2e09223b6d0c2f82A84cEF85E951245Ce567;
    address private constant NEW_VOTER = 0x2215aB2e64490bC8E9308d0371e708845a796A29;
    address private constant NEW_VOTING_ESCROW = 0xA906901429F62708A587EA1fC5Fef6C850AA5F9b;
    address payable private constant NEW_ROUTER = payable(0xCe30506F6c1Cea34aC704f93d51d55058791E497);
    address private constant NEW_MINTER = 0xb074FeF76F0b5B544e4337226d4f9eB54E46ee3F;

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
            "Option to buy FLOW", // name
            "oFLOW", // symbol
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
