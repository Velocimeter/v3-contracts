// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {IFlow} from "contracts/interfaces/IFlow.sol";
import {AutoBribe} from "contracts/AutoBribe.sol";

contract AutoBribeDeploy is Script {
    // token addresses
    address private constant FVM = 0x07BB65fAaC502d4996532F834A1B7ba5dC32Ff96;
    address private constant TEAM_MULTI_SIG = 0x88Dec6df03C2C111Efd4ad89Cef2c0347034AFC0;
    address private constant EOA = 0xcC06464C7bbCF81417c08563dA2E1847c22b703a;

    // xx_wrapped_bribe contracts
    address private constant skull_wftm = 0x53b063a0D87119A9e397ff6910EBd3c7e2Ad06E9;


    //TODO: these should be set BEFORE run()
    address private constant WRAPPED_BRIBE = skull_wftm; // TODO: change wrapped bribe address
    string private constant name = "SKULL_WFTM_Autobribe"; // give the contract a unique name
    address private constant PROJECT = 0x33b65eddB6896a236b281B8bb0A9E4028768BDb6; //supply the projects wallet address here

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("VOTE_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        AutoBribe autoBribe = new AutoBribe(
            WRAPPED_BRIBE,
            EOA,
            name
        );

        // autoBribe.initProject(PROJECT);
        // autoBribe.transferOwnership(TEAM_MULTI_SIG);

        vm.stopBroadcast();
    }
}



