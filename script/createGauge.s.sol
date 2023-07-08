// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

// Scripting tool
import "forge-std/console2.sol";
import {Script} from "../lib/forge-std/src/Script.sol";
import {Voter} from "../contracts/Voter.sol";

contract createGauge is Script { 

    address private pair = 0x487079F7311e8B5159e1B1572F8faAF805ec7D1E;
    address private GRAINPair = 0xB6220893EFC07f942972D266AB8f8867995d2278;
    address private FBombPair = 0xB4A46699427F6C40072706067b7DF62823d69466;
    address private voterAddy =  0xc9Ea7A2337f27935Cd3ccFB2f725B0428e731FBF;

    function run () external {
        uint256 votePrivateKey = vm.envUint("VOTE_PRIVATE_KEY");
        vm.startBroadcast(votePrivateKey);

            Voter voter = Voter(voterAddy);
                    
            voter.createGauge(FBombPair, 0);

        vm.stopBroadcast();

    } 
}

// forge script script/createGauge.s.sol:createGauge --rpc-url https://rpc.ftm.tools  -vvvv --broadcast --gas-estimate-multiplier 20