// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

// Scripting tool
import "forge-std/console2.sol";
import {Script} from "../lib/forge-std/src/Script.sol";
import {VotingEscrow} from "../contracts/VotingEscrow.sol";

contract Spliter is Script { 

    address private veFVM = 0xAE459eE7377Fb9F67518047BBA5482C2F0963236;
    address private POVP;

    uint private total =  90000000000000000000000;

    function run () external {
        uint256 votePrivateKey = vm.envUint("VOTE_PRIVATE_KEY");
        vm.startBroadcast(votePrivateKey);

        split();

        vm.stopBroadcast();

    } 
    function split() private {
    VotingEscrow votingescrow = VotingEscrow(veFVM);

    uint[] memory splits = new uint[](4);
    splits[0] = 25;
    splits[1] = 25;
    splits[2] = 25;
    splits[3] = 25;

    votingescrow.split(splits, 2);

    }

}