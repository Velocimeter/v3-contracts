// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {VotingEscrow} from "../contracts/VotingEscrow.sol";

contract VotingEscrowSetArtProxy is Script {
    // TODO: set variables
    address private constant TEAM_MULTI_SIG = 0x13eeB8EdfF60BbCcB24Ec7Dd5668aa246525Dc51;
    address private constant NEW_VOTING_ESCROW = 0xA1B589FB7e04d19CEC391834131158f7F9d2D168;
    address private constant VEART = 0x976f09807fF78aC52D723BD16ad1c07212c62F60;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        VotingEscrow(NEW_VOTING_ESCROW).setArtProxy(VEART);

        // Set Voting escrow team
        VotingEscrow(NEW_VOTING_ESCROW).setTeam(TEAM_MULTI_SIG);


        vm.stopBroadcast();
    }
}
