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
        0xfA89A4C7F79Dc4111c116a0f01061F4a7D9fAb73;
    address private constant DEPLOYER =
        0xe0F7921414e79fE4459148d2e38fb68C9186DECC;

    // TODO: Fill the address
    address private constant WETH = 0x4200000000000000000000000000000000000006;
    address private constant NEW_FLOW = 0xd386a121991E51Eab5e3433Bf5B1cF4C8884b47a;
    address private constant NEW_PAIR_FACTORY = 0xe21Aac7F113Bd5DC2389e4d8a8db854a87fD6951;
    address private constant NEW_GAUGE_FACTORY = 0x96600B4293DA981554805cCbAB88B48B4C54fAA8;
    address private constant NEW_VOTER = 0xab9B68c9e53c94D7c0949FB909E80e4a29F9134A;
    address private constant NEW_VOTING_ESCROW = 0x91F85d68B413dE823684c891db515B0390a02512;
    address payable private constant NEW_ROUTER = payable(0xE11b93B61f6291d35c5a2beA0A9fF169080160cF);
    address private constant NEW_MINTER = 0x2F54d40E246eaBA24301dD4480fCCF36B856D578;

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
            "Option to buy BVM", // name
            "oBVM", // symbol
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

        GaugeFactoryV3(NEW_GAUGE_FACTORY).setOFlow(address(oFlow));

        // Transfer gaugefactory ownership to MSIG (team)
        GaugeFactoryV3(NEW_GAUGE_FACTORY).transferOwnership(TEAM_MULTI_SIG);

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
