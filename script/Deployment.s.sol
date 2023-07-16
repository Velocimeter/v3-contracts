// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";

import {Flow} from "../contracts/Flow.sol";
import {GaugeFactoryV3} from "../contracts/factories/GaugeFactoryV3.sol";
import {BribeFactory} from "../contracts/factories/BribeFactory.sol";
import {PairFactory} from "../contracts/factories/PairFactory.sol";
import {Router} from "../contracts/Router.sol";
import {VelocimeterLibrary} from "../contracts/VelocimeterLibrary.sol";
import {VeArtProxy} from "../contracts/VeArtProxy.sol";
import {VotingEscrowV2} from "../contracts/VotingEscrowV2.sol";
import {RewardsDistributor} from "../contracts/RewardsDistributor.sol";
import {Voter} from "../contracts/Voter.sol";
import {Minter} from "../contracts/Minter.sol";
import {MintTank} from "../contracts/MintTank.sol";
import {AirdropClaim} from "../contracts/AirdropClaim.sol";
import {OptionTokenV2} from "../contracts/OptionTokenV2.sol";
import {IERC20} from "../contracts/interfaces/IERC20.sol";
import {IPair} from "../contracts/interfaces/IPair.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract Deployment is Script {
    // token addresses
    // TODO: check token address
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

    // privileged accounts
    // TODO: change these accounts!
    address private constant TEAM_MULTI_SIG =
        0x13eeB8EdfF60BbCcB24Ec7Dd5668aa246525Dc51;
    address private constant TANK = 0x0A868fd1523a1ef58Db1F2D135219F0e30CBf7FB;
    address private constant DEPLOYER =
        0xD93142ED5B85FcA4550153088750005759CE8318;
    // TODO: set the following variables
    uint private constant INITIAL_MINT_AMOUNT = 551753842114232799703229867 / 1000 + 1;
    int128 private constant MAX_LOCK_TIME = 2 * 365 * 86400;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Flow token
        Flow flow = new Flow(DEPLOYER, INITIAL_MINT_AMOUNT);

        // Gauge factory
        GaugeFactoryV3 gaugeFactory = new GaugeFactoryV3();

        // Bribe factory
        BribeFactory bribeFactory = new BribeFactory();

        // Pair factory
        PairFactory pairFactory = new PairFactory();

        // Router
        Router router = new Router(address(pairFactory), WCANTO);

        // VelocimeterLibrary
        new VelocimeterLibrary(address(router));

        // VotingEscrowV2
        VotingEscrowV2 votingEscrow = new VotingEscrowV2(
            address(flow),
            address(0),
            TEAM_MULTI_SIG,
            MAX_LOCK_TIME
        );

        // RewardsDistributor
        RewardsDistributor rewardsDistributor = new RewardsDistributor(
            address(votingEscrow)
        );

        // Voter
        Voter voter = new Voter(
            address(votingEscrow),
            address(pairFactory),
            address(gaugeFactory),
            address(bribeFactory)
        );

        // Set voter
        votingEscrow.setVoter(address(voter));
        pairFactory.setVoter(address(voter));

        // Minter
        Minter minter = new Minter(
            address(voter),
            address(votingEscrow),
            address(rewardsDistributor)
        );

        flow.transfer(
            address(TEAM_MULTI_SIG),
            INITIAL_MINT_AMOUNT
        );

        Flow(OLD_FLOW).approve(OLD_ROUTER, 1e18);
        uint256[] memory amounts = Router(OLD_ROUTER)
            .swapExactTokensForTokensSimple(
                1e18,
                IPair(OLD_SCANTO_FLOW_PAIR).getAmountOut(1e18, OLD_FLOW),
                OLD_FLOW,
                LIQUID_STAKED_CANTO,
                false,
                DEPLOYER,
                block.timestamp
            );
        flow.approve(address(router), 1e18);
        router.addLiquidity(
            LIQUID_STAKED_CANTO,
            address(flow),
            false,
            amounts[0],
            1e18 / 1000, // Conversion ratio
            0,
            0,
            DEPLOYER,
            block.timestamp
        );

        // Option to buy Flow
        OptionTokenV2 oFlow = new OptionTokenV2(
            "Option to buy FLOW", // name
            "oFLOW", // symbol
            TEAM_MULTI_SIG, // admin
            LIQUID_STAKED_CANTO, // payment token
            address(flow), // underlying token
            IPair(
                pairFactory.getPair(address(flow), LIQUID_STAKED_CANTO, false)
            ), // pair
            address(gaugeFactory), // gauge factory
            TEAM_MULTI_SIG, // treasury
            address(voter),
            address(votingEscrow),
            address(router)
        );

        // NOTE: comment this out to emit liquid FLOW
        gaugeFactory.setOFlow(address(oFlow));

        // Create gauge for flowWftm pair
        voter.createGauge(
            pairFactory.getPair(address(flow), LIQUID_STAKED_CANTO, false),
            0
        );

        // Update gauge in Option Token contract
        oFlow.updateGauge();

        // Set flow minter to contract
        flow.setMinter(address(minter));

        // Set pair factory pauser and tank
        pairFactory.setTank(TANK);

        // Set minter and voting escrow's team
        votingEscrow.setTeam(TEAM_MULTI_SIG);
        minter.setTeam(TEAM_MULTI_SIG);

        // Transfer pairfactory ownership to MSIG (team)
        pairFactory.transferOwnership(TEAM_MULTI_SIG);

        // Transfer gaugefactory ownership to MSIG (team)
        gaugeFactory.transferOwnership(TEAM_MULTI_SIG);

        // Set voter's emergency council
        voter.setEmergencyCouncil(TEAM_MULTI_SIG);

        // Set voter's governor
        voter.setGovernor(TEAM_MULTI_SIG);

        // Set rewards distributor's depositor to minter contract
        rewardsDistributor.setDepositor(address(minter));

        // Initialize tokens for voter
        address[] memory whitelistedTokens = new address[](3);
        whitelistedTokens[0] = address(flow);
        whitelistedTokens[1] = WCANTO;
        whitelistedTokens[2] = address(oFlow);
        voter.initialize(whitelistedTokens, address(minter));

        vm.stopBroadcast();
    }
}
