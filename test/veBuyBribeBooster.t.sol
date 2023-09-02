pragma solidity 0.8.13;

import "./BaseTest.sol";
import "contracts/veBuyBribeBooster.sol";

contract veBuyBribeBoosterTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    veBuyBribeBooster veBuyBribeBoosterContract;
    ExternalBribe bribe;

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

        address gauge = voter.createGauge(address(flowDaiPair), 0);
        bribe = ExternalBribe(voter.external_bribes(gauge));
       
        veBuyBribeBoosterContract = new veBuyBribeBooster(address(escrow),address(owner),address(DAI),10000000,address(router),address(oFlow),address(voter));
        FLOW.approve(address(veBuyBribeBoosterContract),TOKEN_1 * 10);
        veBuyBribeBoosterContract.donateFlow(TOKEN_1 * 10);

        oFlow.grantRole(oFlow.MINTER_ROLE(), address(veBuyBribeBoosterContract));

        voter.whitelist(address(oFlow));
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
       DAI.approve(address(veBuyBribeBoosterContract), TOKEN_1);
       uint256 flowAmount = router.getAmountOut(TOKEN_1, address(DAI), address(FLOW), false);
       uint256 daiBalanceBefore = DAI.balanceOf(address(owner));
       uint256 oTokenBalanceBeforeBribe = oFlow.balanceOf(address(bribe));
       uint256 maxNFT = escrow.currentTokenId(); 
       
        veBuyBribeBoosterContract.boostedBuyAndVeLock(TOKEN_1,1,address(flowDaiPair));
    
        uint256 daiBalanceAfter = DAI.balanceOf(address(owner));
         uint256 oTokenBalanceBeforeAfter = oFlow.balanceOf(address(bribe));
        
        assertEq(escrow.currentTokenId(),maxNFT + 1);
        
        (int128 amount,uint256 duration) =  escrow.locked(maxNFT + 1);

        assertEq(daiBalanceBefore - daiBalanceAfter, TOKEN_1);
        assertEq(oTokenBalanceBeforeAfter - oTokenBalanceBeforeBribe, 333311110370345678 * 2);
        assertEq(amount,333311110370345678);
        assertEq(duration,9676800);
    }

}