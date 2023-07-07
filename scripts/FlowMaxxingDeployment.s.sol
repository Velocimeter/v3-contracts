// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import { Script } from "../lib/forge-std/src/Script.sol";

import { IERC20 } from "../contracts/interfaces/IERC20.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

import { Pair } from "../contracts/Pair.sol";
import { FLOWMaxxing } from "../contracts/FLOWMAXXING.sol";
import { OptionTokenV2 } from "../contracts/OptionTokenV2.sol";

contract FLOWMAXXINGDeployment is Script {
  address private constant USDC = 0x15D38573d2feeb82e7ad5187aB8c1D52810B1f07;

  address private constant FLOW = 0x39b9D781dAD0810D07E24426c876217218Ad353D;
  address private constant FLOWUSDC = 0xd166B6BAcDeC273dD457DD3aDeF9708dcB26734A; //pair address
  address private constant VEADDRESS = 0xe7b8F4D74B7a7b681205d6A3D231d37d472d4986;

  address private constant VOTER = 0x8C4FF4004c8a85054639B86E9F8c26e9DA7ff738;
  address private constant ROUTER = 0x370d160992C8C48BCCFcf009f0c9db9d00574eF7;

  address private constant TEAM_MULTI_SIG =
    0x069e85D4F1010DD961897dC8C095FBB5FF297434;  

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    vm.startBroadcast(deployerPrivateKey);

    // Option to buy Agg
    OptionTokenV2 oFlow = new OptionTokenV2(
      "Option to buy FLOW", // name
      "oFLOW", // symbol
      TEAM_MULTI_SIG, // admin
      USDC, // payment token
      FLOW, // underlying
      Pair(FLOWUSDC), // pair
      TEAM_MULTI_SIG, // used to be gauge factory but just grants admin role
      TEAM_MULTI_SIG, // treasury
      VOTER,
      VEADDRESS,
      ROUTER
    );

    // Initialize tokens for gauge
    address[] memory whitelistedTokens = new address[](4);
    whitelistedTokens[0] = address(oFlow);
    whitelistedTokens[1] = USDC;
    whitelistedTokens[2] = FLOW;
   
    // whitelistedTokens[3] = FLOW;  // never give flow directly

    FLOWMaxxing gauge = new FLOWMaxxing(
      FLOWUSDC,
      address(0),
      VEADDRESS,
      VOTER,
      FLOW,
      address(oFlow),
      TEAM_MULTI_SIG,
      true,
      whitelistedTokens
    );

    vm.stopBroadcast();
  }
}
