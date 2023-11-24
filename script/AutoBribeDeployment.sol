pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";
import {AutoBribe} from "../contracts/AutoBribe.sol";

contract AutoBribeDeployment is Script {

        address constant MSIG = 0x88Dec6df03C2C111Efd4ad89Cef2c0347034AFC0;
        address constant PROJECT = 0x6e74053a3798e0fC9a9775F7995316b27f21c4D2;

        address constant DEPLOYER = 0x3b91Ca4D89B5156d456CbD0D6305F7f36B1517a4;

        function run() external {
            uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

            vm.startBroadcast(deployerPrivateKey);
            
            AutoBribe autoBribeContract = new AutoBribe(0x00A94bBB532dfD02471B549b921f86e21b46b539,DEPLOYER,"WETH/frxETH");
            autoBribeContract.initProject(PROJECT);
            autoBribeContract.transferOwnership(MSIG);

            AutoBribe autoBribeContract2 = new AutoBribe(0x20dc2d6d9BB2B47231BD561595B0488672f3e41e,DEPLOYER,"USDC/FRAX");
            autoBribeContract2.initProject(PROJECT);
            autoBribeContract2.transferOwnership(MSIG);


            AutoBribe autoBribeContract3 = new AutoBribe(0xc558361aD89BC7313D643761Ae8D5D905077d853,DEPLOYER,"ERN/FRAX");
            autoBribeContract3.initProject(PROJECT);
            autoBribeContract3.transferOwnership(MSIG);
            
            vm.stopBroadcast();
        }
}