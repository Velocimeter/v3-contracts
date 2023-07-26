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
    address private constant WCANTO =
        0x826551890Dc65655a0Aceca109aB11AbDbD7a07B;

    // privileged accounts
    // TODO: change these accounts!
    address private constant TEAM_MULTI_SIG =
        0x13eeB8EdfF60BbCcB24Ec7Dd5668aa246525Dc51;
    address private constant TANK = 0x0A868fd1523a1ef58Db1F2D135219F0e30CBf7FB;
    address private constant DEPLOYER =
        0x560361d945A7F16Fb5Ea219AE06d2C47bB6ccb53;
    // TODO: set the following variables
    uint private constant INITIAL_MINT_AMOUNT =
        (564186852951191807807800273 + 10632790188764001321559579) /
            uint(1000) +
            1;
    int128 private constant MAX_LOCK_TIME = 2 * 365 * 86400;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Flow token
        Flow flow = new Flow(DEPLOYER, INITIAL_MINT_AMOUNT, TEAM_MULTI_SIG);
        uint256 csrNftId = flow.csrNftId();

        // Gauge factory
        GaugeFactoryV3 gaugeFactory = new GaugeFactoryV3(csrNftId);

        // Bribe factory
        BribeFactory bribeFactory = new BribeFactory(csrNftId);

        // Pair factory
        PairFactory pairFactory = new PairFactory(csrNftId);

        // Router
        Router router = new Router(address(pairFactory), WCANTO, csrNftId);

        // VelocimeterLibrary
        new VelocimeterLibrary(address(router));

        // VotingEscrowV2
        VotingEscrowV2 votingEscrow = new VotingEscrowV2(
            address(flow),
            address(0),
            TEAM_MULTI_SIG,
            MAX_LOCK_TIME,
            csrNftId
        );

        // RewardsDistributor
        RewardsDistributor rewardsDistributor = new RewardsDistributor(
            address(votingEscrow),
            csrNftId
        );

        // Voter
        Voter voter = new Voter(
            address(votingEscrow),
            address(pairFactory),
            address(gaugeFactory),
            address(bribeFactory),
            csrNftId
        );

        // Set voter
        votingEscrow.setVoter(address(voter));
        pairFactory.setVoter(address(voter));

        // Minter
        Minter minter = new Minter(
            address(voter),
            address(votingEscrow),
            address(rewardsDistributor),
            csrNftId
        );

        flow.transfer(
            address(TEAM_MULTI_SIG),
            INITIAL_MINT_AMOUNT - 1e18 / 1000
        );

        // Set flow minter to contract
        flow.setMinter(address(minter));

        // Set pair factory pauser and tank
        pairFactory.setTank(TANK);

        // Set minter and voting escrow's team
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
