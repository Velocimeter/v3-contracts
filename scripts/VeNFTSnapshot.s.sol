// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import "forge-std/console2.sol";
import {Script} from "../lib/forge-std/src/Script.sol";

import {VotingEscrow} from "../contracts/VotingEscrow.sol";

contract VeNFTSnapshot is Script {
    function run() external  {
        VotingEscrow votingEscrow = VotingEscrow(0x990efF367C6c4aece43c1E98099061c897730F27);
        // From https://alto.build/collections/0x990eff367c6c4aece43c1e98099061c897730f27
        uint256 currentTokenId = 0;
        uint256 maxTokenId = 267;
        while (currentTokenId <= maxTokenId) {
            address owner = votingEscrow.ownerOf(currentTokenId);

            if (owner != address(0)) {
                (int128 lockAmount,) = votingEscrow.locked(currentTokenId);

                vm.writeLine("text.txt", "Token ID: ");
                vm.writeLine("text.txt", vm.toString(currentTokenId));
                vm.writeLine("text.txt", "Owner: ");
                vm.writeLine("text.txt", vm.toString(owner));
                vm.writeLine("text.txt", "Locked amount: ");
                vm.writeLine("text.txt", vm.toString(lockAmount));
            }

            currentTokenId++;
        }
    }
}
