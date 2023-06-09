// SPDX-License-Identifier: MIT

//   forge script scripts/MintTankUse.s.sol:MintTankUse --rpc-url https://rpc.pulsechain.com -vvvv --broadcast --slow

pragma solidity 0.8.13;

// Scripting tool
import "forge-std/console2.sol";
import {Script} from "../lib/forge-std/src/Script.sol";
import {MintTank} from "../contracts/MintTank.sol";
import {Flow} from "../contracts/Flow.sol";

uint256 constant MAX_LOCK = 26 * 7 * 86400;

//TO:DO set these for each user
address constant 1 = 0xe5;

contract MintTankUse is Script {
    function run() external {
        uint256 votePrivateKey = vm.envUint("VOTE_PRIVATE_KEY");
        vm.startBroadcast(votePrivateKey);

        MintTank mintTank = MintTank(0xbB7bbd0496c23B7704213D6dbbe5C39eF8584E45);

        mintTank.mintFor(amt, MAX_LOCK, ser);
        mintTank.mintFor(amt, MAX_LOCK, ser);

       
    
        vm.stopBroadcast();
        }
    }
