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
import {VotingEscrow} from "../contracts/VotingEscrow.sol";
import {RewardsDistributor} from "../contracts/RewardsDistributor.sol";
import {Voter} from "../contracts/Voter.sol";
import {Minter} from "../contracts/Minter.sol";
import {IERC20} from "../contracts/interfaces/IERC20.sol";
import {IPair} from "../contracts/interfaces/IPair.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract Deployment is Script {
    // token addresses
    // TODO: check token address
    address private constant WETH = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;

    // privileged accounts
    // TODO: change these accounts!
    address private constant TEAM_MULTI_SIG =
        0x5b86A94b14Df577cCf2eA19d4f28560161B77715;
    address private constant TANK = 0x5b86A94b14Df577cCf2eA19d4f28560161B77715;
    address private constant DEPLOYER =
        0xC5037bf0A31062aC92975f5FDfDd4b8d8A4be76B;
    // TODO: set the following variables
    uint private constant INITIAL_MINT_AMOUNT = 6_000_000e18;

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
        Router router = new Router(address(pairFactory), WETH);

        // VelocimeterLibrary
        new VelocimeterLibrary(address(router));

        // VotingEscrow
        VotingEscrow votingEscrow = new VotingEscrow(
            address(flow),
            address(0),
            TEAM_MULTI_SIG
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

        flow.transfer(address(TEAM_MULTI_SIG), INITIAL_MINT_AMOUNT - 1e18);

        // Set flow minter to contract
        flow.setMinter(address(minter));

        // Set pair factory pauser and tank
        pairFactory.setTank(TANK);

        // Set minter and voting escrow's team
        votingEscrow.setTeam(TEAM_MULTI_SIG);
        minter.setTeam(TEAM_MULTI_SIG);

        // Transfer pairfactory ownership to MSIG (team)
        pairFactory.transferOwnership(TEAM_MULTI_SIG);

        // Set voter's emergency council
        voter.setEmergencyCouncil(TEAM_MULTI_SIG);

        // Set voter's governor
        voter.setGovernor(TEAM_MULTI_SIG);

        // Set rewards distributor's depositor to minter contract
        rewardsDistributor.setDepositor(address(minter));

        vm.stopBroadcast();
    }
}
