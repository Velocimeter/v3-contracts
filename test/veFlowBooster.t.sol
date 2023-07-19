pragma solidity 0.8.13;

import "./BaseTest.sol";
import "contracts/veFlowBooster.sol";

contract veFlowBoosterTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    ExternalBribe xbribe;
    veFlowBooster veFlowBoosterContract;

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

       
        veFlowBoosterContract = new veFlowBooster(address(escrow),address(owner),address(DAI),10000000,address(router));
        FLOW.approve(address(veFlowBoosterContract),TOKEN_1 * 10);
        veFlowBoosterContract.donateFlow(TOKEN_1 * 10);
    }

    function deployVoter() public {
        gaugeFactory = new GaugeFactory();
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
        deployOptionTokenWithOwner(address(owner), address(gaugeFactory));
        gaugeFactory.setOFlow(address(oFlow));
    }

    function testBoostedBuyAndVeLock() public {
       DAI.approve(address(veFlowBoosterContract), TOKEN_1);
       uint256 flowAmount = router.getAmountOut(TOKEN_1, address(DAI), address(FLOW), false);
       uint256 daiBalanceBefore = DAI.balanceOf(address(owner2));
       uint256 maxNFT = escrow.currentTokenId(); 
       
       veFlowBoosterContract.boostedBuyAndVeLock(TOKEN_1,1);
    
        uint256 daiBalanceAfter = DAI.balanceOf(address(owner2));
        
        assertEq(escrow.currentTokenId(),maxNFT + 1);
        
        (int128 amount,uint256 duration) =  escrow.locked(maxNFT + 1);

        assertEq(daiBalanceAfter - daiBalanceAfter, TOKEN_1);
        assertEq(amount,999933331111037034);
        assertEq(duration,9676800);
    }

}