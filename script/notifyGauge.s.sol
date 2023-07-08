// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

// Scripting tool
import "forge-std/console2.sol";
import {Script} from "../lib/forge-std/src/Script.sol";
import {Gauge} from "../contracts/Gauge.sol";
import {IERC20} from "../contracts/interfaces/IERC20.sol";

contract notifyGauge is Script { 

    mapping (address => uint) gaugeAmounts;
    mapping (uint => address) gauges;
    address private oFVM = 0xF9EDdca6B1e548B0EC8cDDEc131464F462b8310D;
    address private FVM = 0x07BB65fAaC502d4996532F834A1B7ba5dC32Ff96;

    function setEmits() internal {

        gauges[0] = 0x39E18682f0e988f667E18F193Fb525fC2532f854;
        gauges[1] = 0xd5A0924Bb5D7D315165D63ea7E05c35aB4BcFc1F;
        gauges[2] = 0xF89f367E0225fE68c7c28Fad0BaDc7f569987cFe;
        gauges[3] = 0xe0e136F218d89111eC81aE5Bf89659c59e7a1F19;
        gauges[4] = 0x8644F6258DE46b1498bD904b0a3496ea5458Bcc4;
        gauges[5] = 0x95c442dcc50eA5bc3B67B85a8B238658301Ad0d1;
        gauges[6] = 0x5511782e2b9432fd9C8DddecDe886C626aB77E0C; 
        gauges[7] = 0x2c522196AdbA4370268168f93f47f5C73B9862c5; 
        gauges[8] = 0xa3643a5d5B672a267199227CD3E95eD0B41DBD52; 
        gauges[9] = 0x53929aFc4ef21EDf9534a527eb2C108975eF66aE; 
        gauges[10] = 0x4295f08edA17941740975C03cc4541fedbCAf8de; 
        gauges[11] = 0xbb538ABc3A584073396E4058152d1B1c67592b3D; 
        gauges[12] = 0x38ED4DC09A7a810053EAC923bff4D1d8C2cF4D62;
        gauges[13] = 0x59a4ef99777ca803200ddd06E3244a2d11B05B7c; 
        gauges[14] = 0xD12880EFA97b79494181E29e4B112F94c9737FeE; 
        gauges[15] = 0xCb217A8f665f305Acd6c0BB6860230Da2fb86bca; 
        gauges[16] = 0xce689647318C502FF4E1B79C1BB0Daa3aC9b0c76; 
        gauges[17] = 0xE9C1F774E59927dE112B92a70e6E78deb0D62fDA; 
        gauges[18] = 0xd7f1E7B165Cd7262A5DAE23a919440645d1Bf31d; 
        gauges[19] = 0x051ee4773f244d57934bB72B071669349141edce; 
  

        gaugeAmounts[0x39E18682f0e988f667E18F193Fb525fC2532f854] = 2506751217907469030246;
        gaugeAmounts[0xd5A0924Bb5D7D315165D63ea7E05c35aB4BcFc1F] = 4359341147761345553100;
        gaugeAmounts[0xF89f367E0225fE68c7c28Fad0BaDc7f569987cFe] = 19188325113367067180553;
        gaugeAmounts[0xe0e136F218d89111eC81aE5Bf89659c59e7a1F19] = 7516839570330996615425;
        gaugeAmounts[0x8644F6258DE46b1498bD904b0a3496ea5458Bcc4] = 11076448960666523296161;
        gaugeAmounts[0x95c442dcc50eA5bc3B67B85a8B238658301Ad0d1] = 16697018081403402190505;
        gaugeAmounts[0x5511782e2b9432fd9C8DddecDe886C626aB77E0C] = 9924674699241251399601;
        gaugeAmounts[0x2c522196AdbA4370268168f93f47f5C73B9862c5] = 250519645252272215499;
        gaugeAmounts[0xa3643a5d5B672a267199227CD3E95eD0B41DBD52] = 36831819255174566726711;
        gaugeAmounts[0x53929aFc4ef21EDf9534a527eb2C108975eF66aE] = 5008833609875442340816;
        gaugeAmounts[0x4295f08edA17941740975C03cc4541fedbCAf8de] = 2555611919103018622049;
        gaugeAmounts[0xbb538ABc3A584073396E4058152d1B1c67592b3D] = 3508907991001230952379;
        gaugeAmounts[0x38ED4DC09A7a810053EAC923bff4D1d8C2cF4D62] = 7512853405889840030313;
        gaugeAmounts[0x59a4ef99777ca803200ddd06E3244a2d11B05B7c] = 5008833609875442340816;
        gaugeAmounts[0xD12880EFA97b79494181E29e4B112F94c9737FeE] = 2266986009246662167312;
        gaugeAmounts[0xCb217A8f665f305Acd6c0BB6860230Da2fb86bca] = 397834011222275993;
        gaugeAmounts[0xce689647318C502FF4E1B79C1BB0Daa3aC9b0c76] = 3646876995710625561492;
        gaugeAmounts[0xE9C1F774E59927dE112B92a70e6E78deb0D62fDA] = 2203886788345194629959;
        gaugeAmounts[0xd7f1E7B165Cd7262A5DAE23a919440645d1Bf31d] = 2404240132740212323591;
        gaugeAmounts[0x051ee4773f244d57934bB72B071669349141edce] = 7530834013096213156473;
    }

    function run () external {
        setEmits();
        uint256 votePrivateKey = vm.envUint("VOTE_PRIVATE_KEY");
        vm.startBroadcast(votePrivateKey);

             uint256 start = 0;
             uint256 end = 19;
            uint256 total = 0;
             while (start <= end) {
                 address gaugeAddress = gauges[start];
                 console2.log(gaugeAddress,gaugeAmounts[gaugeAddress]);
                 require(gaugeAmounts[gaugeAddress] > Gauge(gaugeAddress).left(oFVM));
                 IERC20(oFVM).approve(gaugeAddress, gaugeAmounts[gaugeAddress]);
                 Gauge(gaugeAddress).notifyRewardAmount(oFVM, gaugeAmounts[gaugeAddress]);
                 start++;
                 total += gaugeAmounts[gaugeAddress];
             }
            console2.log("total",total);
                    

         vm.stopBroadcast();

    } 
}

// forge script script/createGauge.s.sol:createGauge --rpc-url https://rpc.ftm.tools  -vvvv 
