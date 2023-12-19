// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {IFlow} from "contracts/interfaces/IFlow.sol";
import {Voter} from "contracts/Voter.sol";
import "forge-std/console2.sol";


contract CHECK is Script {
    function run() external {

        uint256 PrivateKey = vm.envUint("VOTE_PRIVATE_KEY");
        vm.startBroadcast(PrivateKey);

        Voter cvmvoter = Voter(0xd5FA5bfd83ea4A088a3A28E12AD6494750aC7B8c);

        address gov = cvmvoter.governor();
        console2.log(gov, "governor");
    }


}
// forge script script/checkCaller.s.sol:CHECK  --rpc-url https://jsonrpc.canto.nodestake.top	

