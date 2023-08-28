pragma solidity 0.8.13;

import "./BaseTest.sol";
import "contracts/veBribeBooster.sol";

contract veBribeBoosterTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    ExternalBribe bribe;
    veBribeBooster veBribeBoosterContract;

    function setUp() public {
        deployOwners();
        deployCoins();
        mintStables();
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1e27;
        amounts[1] = 1e27;
        amounts[2] = 1e27;
        mintFlow(owners, amounts);

        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(FLOW), address(artProxy), owners[0]);

        deployPairFactoryAndRouter();
        deployVoter();
        factory.setFee(true, 2); // 2 bps = 0.02%
        deployPairWithOwner(address(owner));

        address gauge = voter.createGauge(address(flowDaiPair), 0);
        bribe = ExternalBribe(voter.external_bribes(gauge));
        washTrades();
        washTrades2();

        voter.whitelist(address(FRAX));
       
        veBribeBoosterContract = new veBribeBooster(address(escrow),address(voter),address(owner),10000000,address(DAI),address(flowDaiPair),25);
        FLOW.approve(address(veBribeBoosterContract),TOKEN_1 * 10);
        veBribeBoosterContract.donateFlow(TOKEN_1 * 10);
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

     function washTrades() public {
        FLOW.approve(address(router), TOKEN_100K);
        DAI.approve(address(router), TOKEN_100K);
        router.addLiquidity(
            address(FLOW),
            address(DAI),
            false,
            TOKEN_100K,
            TOKEN_100K,
            0,
            0,
            address(owner),
            block.timestamp
        );

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(FLOW), address(DAI), false);
        Router.route[] memory routes2 = new Router.route[](1);
        routes2[0] = Router.route(address(DAI), address(FLOW), false);

        uint256 i;
        for (i = 0; i < 10; i++) {
            vm.warp(block.timestamp + 1801);
            assertEq(
                router.getAmountsOut(TOKEN_1, routes)[1],
                flowDaiPair.getAmountOut(TOKEN_1, address(FLOW))
            );

            uint256[] memory expectedOutput = router.getAmountsOut(
                TOKEN_1,
                routes
            );
            FLOW.approve(address(router), TOKEN_1);
            router.swapExactTokensForTokens(
                TOKEN_1,
                expectedOutput[1],
                routes,
                address(owner),
                block.timestamp
            );

            assertEq(
                router.getAmountsOut(TOKEN_1, routes2)[1],
                flowDaiPair.getAmountOut(TOKEN_1, address(DAI))
            );

            uint256[] memory expectedOutput2 = router.getAmountsOut(
                TOKEN_1,
                routes2
            );
            DAI.approve(address(router), TOKEN_1);
            router.swapExactTokensForTokens(
                TOKEN_1,
                expectedOutput2[1],
                routes2,
                address(owner),
                block.timestamp
            );
        }
    }

    function washTrades2() public {
        FRAX.approve(address(router), TOKEN_100K);
        DAI.approve(address(router), TOKEN_100K);
        router.addLiquidity(
            address(FRAX),
            address(DAI),
            true,
            TOKEN_100K,
            TOKEN_100K,
            0,
            0,
            address(owner),
            block.timestamp
        );

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(FRAX), address(DAI), true);
        Router.route[] memory routes2 = new Router.route[](1);
        routes2[0] = Router.route(address(DAI), address(FRAX), true);

        uint256 i;
        for (i = 0; i < 10; i++) {
            vm.warp(block.timestamp + 1801);
            assertEq(
                router.getAmountsOut(TOKEN_1, routes)[1],
                pair3.getAmountOut(TOKEN_1, address(FRAX))
            );

            uint256[] memory expectedOutput = router.getAmountsOut(
                TOKEN_1,
                routes
            );
            FRAX.approve(address(router), TOKEN_1);
            router.swapExactTokensForTokens(
                TOKEN_1,
                expectedOutput[1],
                routes,
                address(owner),
                block.timestamp
            );

            assertEq(
                router.getAmountsOut(TOKEN_1, routes2)[1],
                pair3.getAmountOut(TOKEN_1, address(DAI))
            );

            uint256[] memory expectedOutput2 = router.getAmountsOut(
                TOKEN_1,
                routes2
            );
            DAI.approve(address(router), TOKEN_1);
            router.swapExactTokensForTokens(
                TOKEN_1,
                expectedOutput2[1],
                routes2,
                address(owner),
                block.timestamp
            );
        }
    }

    function testBoostedBuyAndVeLock() public {
       DAI.approve(address(veBribeBoosterContract), TOKEN_1);

       uint256 daiBalanceBefore = DAI.balanceOf(address(owner));
       uint256 daiBalanceBeforeBribe = DAI.balanceOf(address(bribe));
       uint256 maxNFT = escrow.currentTokenId(); 
       
       veBribeBoosterContract.boostedBribe(TOKEN_1, address(DAI), address(flowDaiPair));
    
       uint256 daiBalanceAfter = DAI.balanceOf(address(owner));
       uint256 daiBalanceAfterBribe = DAI.balanceOf(address(bribe));
        
       assertEq(escrow.currentTokenId(),maxNFT + 1);
        
        (int128 amount,uint256 duration) =  escrow.locked(maxNFT + 1);

        assertEq(daiBalanceBefore - daiBalanceAfter, TOKEN_1);
        assertEq(daiBalanceAfterBribe - daiBalanceBeforeBribe, TOKEN_1);
        assertEq(amount,249997499700122104);
        assertEq(duration,9676800);
    }

    function testBoostedBuyAndVeLockWithNotRouteAsset() public {
       veBribeBoosterContract.whitelist(address(FRAX), address(pair3), TOKEN_1 * 10,25);

       FRAX.approve(address(veBribeBoosterContract), TOKEN_1);

       uint256 fraxBalanceBefore = FRAX.balanceOf(address(owner));
       uint256 fraxBalanceBeforeBribe = FRAX.balanceOf(address(bribe));
       uint256 maxNFT = escrow.currentTokenId(); 
       
       veBribeBoosterContract.boostedBribe(TOKEN_1, address(FRAX), address(flowDaiPair));
    
       uint256 fraxBalanceAfter = FRAX.balanceOf(address(owner));
       uint256 fraxBalanceAfterBribe = FRAX.balanceOf(address(bribe));
        
       assertEq(escrow.currentTokenId(),maxNFT + 1);
        
        (int128 amount,uint256 duration) =  escrow.locked(maxNFT + 1);

        assertEq(fraxBalanceBefore - fraxBalanceAfter, TOKEN_1);
        assertEq(fraxBalanceAfterBribe - fraxBalanceBeforeBribe, TOKEN_1);
        assertEq(amount,249997499700121979);
        assertEq(duration,9676800);
    }

}