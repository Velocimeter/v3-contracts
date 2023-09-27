pragma solidity 0.8.13;

import "./BaseTest.sol";
import "contracts/veMastaBooster.sol";
import "contracts/GaugeV3.sol";
import "contracts/factories/GaugeFactoryV3.sol";

contract veMastaBoosterTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactoryV3 gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    veMastaBooster veMastaBoosterContract;
    ExternalBribe bribe;
    GaugeV3 gauge;

    function setUp() public {
        deployOwners();
        deployCoins();
        mintStables();
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = TOKEN_1 * 1000;
        amounts[1] = TOKEN_1 * 1000;
        amounts[2] = TOKEN_1 * 1000;
        mintFlow(owners, amounts);

        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(FLOW), address(artProxy), owners[0]);

        deployPairFactoryAndRouter();
        deployVoter();
        factory.setFee(true, 2); // 2 bps = 0.02%
        deployPairWithOwner(address(owner));

        deployOptionTokenV3WithOwner(
            address(owner),
            address(gaugeFactory),
            address(voter),
            address(escrow)
        );
        gaugeFactory.setOFlow(address(oFlowV3));

        gauge = GaugeV3(voter.createGauge(address(flowDaiPair), 0));
        oFlowV3.updateGauge();
        bribe = ExternalBribe(voter.external_bribes(address(gauge)));
       
        veMastaBoosterContract = new veMastaBooster(address(escrow),address(owner),address(DAI),10000000,address(router),oFlowV3.gauge(),address(oFlowV3.pair()),address(oFlowV3),address(voter),10000000);
        FLOW.approve(address(veMastaBoosterContract),TOKEN_1 * 10);
        veMastaBoosterContract.notifyRewardAmount(TOKEN_1 * 10);

        oFlowV3.grantRole(oFlowV3.MINTER_ROLE(), address(veMastaBoosterContract));

        voter.whitelist(address(oFlowV3));
    }

    function deployVoter() public {
        gaugeFactory = new GaugeFactoryV3();
        bribeFactory = new BribeFactory();

        voter = new Voter(
            address(escrow),
            address(factory),
            address(gaugeFactory),
            address(bribeFactory)
        );

        escrow.setVoter(address(voter));
        factory.setVoter(address(voter));
        deployPairWithOwner(address(owner));
    }

    function testBoostedBuyAndBribe() public {
       DAI.approve(address(veMastaBoosterContract), TOKEN_1);
       uint256 flowAmount = router.getAmountOut(TOKEN_1, address(DAI), address(FLOW), false);
       uint256 daiBalanceBefore = DAI.balanceOf(address(owner));
       uint256 oTokenBalanceBeforeBribe = oFlowV3.balanceOf(address(bribe));
       uint256 maxNFT = escrow.currentTokenId(); 
       
        veMastaBoosterContract.boostedBuyAndBribe(TOKEN_1,1,address(flowDaiPair));
    
        uint256 daiBalanceAfter = DAI.balanceOf(address(owner));
         uint256 oTokenBalanceBeforeAfter = oFlowV3.balanceOf(address(bribe));
        
        assertEq(escrow.currentTokenId(),maxNFT + 1);
        
        (int128 amount,uint256 duration) =  escrow.locked(maxNFT + 1);

        assertEq(daiBalanceBefore - daiBalanceAfter, TOKEN_1);
        assertEq(oTokenBalanceBeforeAfter - oTokenBalanceBeforeBribe, 333311110370345678 * 2);
        assertEq(amount,333311110370345678);
        assertEq(duration,9676800);
    }

    function testBoostedBuyAndVeLock() public {
       DAI.approve(address(veMastaBoosterContract), TOKEN_1);
       uint256 flowAmount = router.getAmountOut(TOKEN_1, address(DAI), address(FLOW), false);
       uint256 daiBalanceBefore = DAI.balanceOf(address(owner));
       uint256 maxNFT = escrow.currentTokenId(); 
       
       veMastaBoosterContract.boostedBuyAndVeLock(TOKEN_1,1);
    
        uint256 daiBalanceAfter = DAI.balanceOf(address(owner));
        
        assertEq(escrow.currentTokenId(),maxNFT + 1);
        
        (int128 amount,uint256 duration) =  escrow.locked(maxNFT + 1);

        assertEq(daiBalanceBefore - daiBalanceAfter, TOKEN_1);
        assertEq(amount,999933331111037034);
        assertEq(duration,9676800);
    }

    function testBoostedBuyAndLPLock() public {
       gaugeFactory.addOTokenFor(address(gauge), address(veMastaBoosterContract));
       DAI.approve(address(veMastaBoosterContract), TOKEN_1);
       uint256 flowAmount = router.getAmountOut(TOKEN_1, address(DAI), address(FLOW), false);
       uint256 daiBalanceBefore = DAI.balanceOf(address(owner));
       
       veMastaBoosterContract.boostedBuyAndLPLock(TOKEN_1,1);
    
        uint256 daiBalanceAfter = DAI.balanceOf(address(owner));

        assertEq(daiBalanceBefore - daiBalanceAfter, TOKEN_1);
        assertEq(gauge.balanceWithLock(address(owner)),222224691385459837);
        assertEq(gauge.lockEnd(address(owner)),10000001);
    }

}