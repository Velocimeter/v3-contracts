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
    address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    // privileged accounts
    // TODO: change these accounts!
    address private constant TEAM_MULTI_SIG =
        0x88Dec6df03C2C111Efd4ad89Cef2c0347034AFC0;
    address private constant TANK = 0xb32d744CAc212cAB825b5Eb9c5ba65d7D1CF3bD8;
    address private constant DEPLOYER =
        0xc9c8449259566cdC82f396FeF5E6EA4b5015708A;
    // TODO: set the following variables
    uint private constant INITIAL_MINT_AMOUNT = 6_000_000e18;
    int128 private constant MAX_LOCK_TIME = 52 * 7 * 86400;
    uint private constant MINT_TANK_AMOUNT = 1_290_000e18;
    uint private constant PREMINT_AMOUNT = 690_000e18;

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
        Router router = new Router(address(pairFactory), WFTM);

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

        // MintTank
        MintTank mintTank = new MintTank(
            address(flow),
            address(votingEscrow),
            TEAM_MULTI_SIG,
            uint256(int256(MAX_LOCK_TIME))
        );

        // Premint for Partners
        // TODO: amend amounts
        flow.approve(address(votingEscrow), PREMINT_AMOUNT);
        votingEscrow.create_lock_for(240_000e18, 52 * 7 * 86400, 0xcC06464C7bbCF81417c08563dA2E1847c22b703a);
        votingEscrow.create_lock_for(90_000e18, 52 * 7 * 86400, 0x5F21E3cA21fc0C33cfA5FB33fc7031f61e34D256);
        votingEscrow.create_lock_for(90_000e18, 52 * 7 * 86400, 0xB1dD2Fdb023cB54b7cc2a0f5D9e8d47a9F7723ce);
        votingEscrow.create_lock_for(90_000e18, 52 * 7 * 86400, 0x83B285E802D76055169B1C5e3bF21702B85b89Cb);
        votingEscrow.create_lock_for(90_000e18, 52 * 7 * 86400, 0x89955a99552F11487FFdc054a6875DF9446B2902);
        votingEscrow.create_lock_for(90_000e18, 52 * 7 * 86400, 0x06917EFCE692CAD37A77a50B9BEEF6f4Cdd36422);

        flow.transfer(address(mintTank), MINT_TANK_AMOUNT);
        flow.transfer(address(TEAM_MULTI_SIG), INITIAL_MINT_AMOUNT - MINT_TANK_AMOUNT - PREMINT_AMOUNT);

        // NOTE: comment out and set pair in OptionToken later
        // IPair flowWftmPair = IPair(
        //     pairFactory.createPair(address(flow), WFTM, false)
        // );

        // Option to buy Flow
        OptionTokenV2 oFlow = new OptionTokenV2(
            "Option to buy FLOW", // name
            "oFLOW", // symbol
            TEAM_MULTI_SIG, // admin
            WFTM, // payment token
            address(flow), // underlying token
            // TODO: change if want to set beforehand
            IPair(address(0)), // pair
            address(gaugeFactory), // gauge factory
            TEAM_MULTI_SIG, // treasury
            address(voter),
            address(votingEscrow),
            address(router)
        );

        // NOTE: comment this out to emit liquid FLOW
        // gaugeFactory.setOFlow(address(oFlow));

        // Create gauge for flowWftm pair
        // voter.createGauge(address(flowWftmPair), 0);

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
        whitelistedTokens[1] = WFTM;
        whitelistedTokens[2] = address(oFlow);
        voter.initialize(whitelistedTokens, address(minter));

        vm.stopBroadcast();
    }
}
