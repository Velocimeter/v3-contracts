// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import { Script } from "../lib/forge-std/src/Script.sol";

import { IERC20 } from "../contracts/interfaces/IERC20.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

import { Pair } from "../contracts/Pair.sol";
import { AggMaxxingGauge } from "../contracts/StandAloneGaugeV2.sol";
import { OptionTokenV2 } from "../contracts/OptionTokenV2.sol";

contract AggDeployment is Script {
  address private constant SCANTO = 0x9F823D534954Fc119E31257b3dDBa0Db9E2Ff4ed;
  address private constant AGG = 0xA649325Aa7C5093d12D6F98EB4378deAe68CE23F;
  address private constant FLOW = 0xB5b060055F0d1eF5174329913ef861bC3aDdF029;
  address private constant AGGSCANTO =
    0x5c87D41bc9Ac200a18179Cc2702D9Bb38c27d8fE;
  address private constant VEADDRESS =
    0xfa01adbAA40f0EEeCEA76b7B18AC8bE064536787;
  address private constant VOTER = 0x2862Bf1ADC96d485B6E85C062b170903DE9A2Bd5;
  address private constant ROUTER = 0x52A18b2386D6221Cf9DbcD4790456a23249e5279;

  address private constant TEAM_MULTI_SIG =
    0x0A868fd1523a1ef58Db1F2D135219F0e30CBf7FB;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    vm.startBroadcast(deployerPrivateKey);

    // Option to buy Agg
    OptionTokenV2 oAgg = new OptionTokenV2(
      "Option to buy AGG", // name
      "oAGG", // symbol
      TEAM_MULTI_SIG, // admin
      SCANTO, // payment token
      AGG, // underlying token
      Pair(AGGSCANTO), // pair
      TEAM_MULTI_SIG, // used to be gauge factory but just grants admin role
      TEAM_MULTI_SIG, // treasury
      VOTER,
      VEADDRESS,
      ROUTER
    );

    // Initialize tokens for gauge
    address[] memory whitelistedTokens = new address[](4);
    whitelistedTokens[0] = address(oAgg);
    whitelistedTokens[1] = SCANTO;
    whitelistedTokens[2] = AGG;
    whitelistedTokens[3] = FLOW;

    AggMaxxingGauge gauge = new AggMaxxingGauge(
      AGGSCANTO,
      address(0),
      VEADDRESS,
      VOTER,
      AGG,
      address(oAgg),
      address(0),
      true,
      whitelistedTokens
    );

    vm.stopBroadcast();
  }
}
