// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {IERC20} from "../contracts/interfaces/IERC20.sol";
import {IFlow} from "../contracts/interfaces/IFlow.sol";
import {IPair} from "../contracts/interfaces/IPair.sol";
import {Flow} from "../contracts/Flow.sol";
import {OptionTokenV3} from "../contracts/OptionTokenV3.sol";
import {GaugeFactoryV3} from "../contracts/factories/GaugeFactoryV3.sol";
import {BribeFactory} from "../contracts/factories/BribeFactory.sol";
import {PairFactory} from "../contracts/factories/PairFactory.sol";
import {Router} from "../contracts/Router.sol";
import {VotingEscrowV2} from "../contracts/VotingEscrowV2.sol";
import {Voter} from "../contracts/Voter.sol";

contract OFlowDeployment is Script {
    address private constant TEAM_MULTI_SIG =
        0x13eeB8EdfF60BbCcB24Ec7Dd5668aa246525Dc51;
    address private constant DEPLOYER =
        0x560361d945A7F16Fb5Ea219AE06d2C47bB6ccb53;

    // TODO: Fill the address
    address private constant OLD_FLOW =
        0xB5b060055F0d1eF5174329913ef861bC3aDdF029;
    address private constant OLD_SCANTO_FLOW_PAIR =
        0x754AeD0D7A61dD3B03084d5bB8285D674D663703;
    address payable private constant OLD_ROUTER =
        payable(0x8e2e2f70B4bD86F82539187A634FB832398cc771);

    address private constant WCANTO =
        0x826551890Dc65655a0Aceca109aB11AbDbD7a07B;
    address private constant LIQUID_STAKED_CANTO =
        0x9F823D534954Fc119E31257b3dDBa0Db9E2Ff4ed;
    address private constant NEW_FLOW = 0xbAD86785eB08fe9d0948B7D9d24523000A177cD0;
    address private constant NEW_PAIR_FACTORY = 0xcC6AC37eafA77ef6C8b9283De89bE64d8030DCaE;
    address private constant NEW_GAUGE_FACTORY = 0x7643736cC28b25FA875F309E3299157d3dc22fE5;
    address private constant NEW_VOTER = 0xd5FA5bfd83ea4A088a3A28E12AD6494750aC7B8c;
    address private constant NEW_VOTING_ESCROW = 0xA1B589FB7e04d19CEC391834131158f7F9d2D168;
    address payable private constant NEW_ROUTER = payable(0x2c8F86334552d062A0d7465C7f524eff15AB046c);
    address private constant NEW_MINTER = 0x2F03f3dDd5A5e2fEc7cC582FB044CDBFa24674fd;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Flow(OLD_FLOW).approve(OLD_ROUTER, 1e18);
        Router(OLD_ROUTER)
            .swapExactTokensForTokensSimple(
                1e18,
                IPair(OLD_SCANTO_FLOW_PAIR).getAmountOut(1e18, OLD_FLOW),
                OLD_FLOW,
                LIQUID_STAKED_CANTO,
                false,
                DEPLOYER,
                block.timestamp + 1000
            );
        uint256 sCantoBalance = IERC20(LIQUID_STAKED_CANTO).balanceOf(DEPLOYER);
        IERC20(LIQUID_STAKED_CANTO).approve(NEW_ROUTER, sCantoBalance);
        Flow(NEW_FLOW).approve(NEW_ROUTER, 1e18 / 1000);
        Router(NEW_ROUTER).addLiquidity(
            LIQUID_STAKED_CANTO,
            NEW_FLOW,
            false,
            sCantoBalance,
            1e18 / 1000, // Conversion ratio
            0,
            0,
            DEPLOYER,
            block.timestamp + 1000
        );

        address pair = PairFactory(NEW_PAIR_FACTORY).getPair(
            NEW_FLOW,
            LIQUID_STAKED_CANTO,
            false
        );

        // Option to buy Flow
        OptionTokenV3 oFlow = new OptionTokenV3(
            "Option to buy CVM", // name
            "oCVM", // symbol
            TEAM_MULTI_SIG, // admin
            LIQUID_STAKED_CANTO, // payment token
            NEW_FLOW, // underlying token
            IPair(pair), // pair
            NEW_GAUGE_FACTORY, // gauge factory
            TEAM_MULTI_SIG,
            NEW_VOTER,
            NEW_VOTING_ESCROW,
            NEW_ROUTER
        );

        GaugeFactoryV3(NEW_GAUGE_FACTORY).setOFlow(address(oFlow));
        GaugeFactoryV3(NEW_GAUGE_FACTORY).setOFlow(address(oFlow));

        address[] memory whitelistedTokens = new address[](4);
        whitelistedTokens[0] = NEW_FLOW;
        whitelistedTokens[1] = WCANTO;
        whitelistedTokens[2] = address(oFlow);
        whitelistedTokens[3] = LIQUID_STAKED_CANTO;
        Voter(NEW_VOTER).initialize(whitelistedTokens, NEW_MINTER);

        // Create gauge for flowWftm pair
        Voter(NEW_VOTER).createGauge(pair, 0);

        // Transfer gaugefactory ownership to MSIG (team)
        GaugeFactoryV3(NEW_GAUGE_FACTORY).transferOwnership(TEAM_MULTI_SIG);

        // Update gauge in Option Token contract
        oFlow.updateGauge();

        vm.stopBroadcast();
    }
}
