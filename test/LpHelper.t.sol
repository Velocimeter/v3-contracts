// 1:1 with Hardhat test
pragma solidity 0.8.13;

import "./BaseTest.sol";
import "contracts/GaugeV4.sol";
import "contracts/LpHelper.sol";
import "contracts/factories/GaugeFactoryV4.sol";

contract OptionTokenV3Test is BaseTest {
    GaugeFactoryV4 gaugeFactory;
    VotingEscrow escrow;
    Voter voter;
    BribeFactory bribeFactory;
    GaugeV4 gauge;
    LpHelper lpHelper;

    error LpHelper_Paused();

    event LiquidityAdded(
        address indexed _pair,
        address indexed _for,
        uint256 _lpAmount,
        bool _depositedInGauge
    );
    event PairFactorySet(address indexed _pairFactory);
    event RouterSet(address indexed _router);
    event PauseStateChanged(bool isPaused);

    function setUp() public {
        deployOwners();
        deployCoins();
        mintStables();
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1e27;
        amounts[1] = 1e27;
        amounts[2] = 1e27;
        mintFlow(owners, amounts);

        gaugeFactory = new GaugeFactoryV4();
        bribeFactory = new BribeFactory();
        VeArtProxy artProxy = new VeArtProxy();

        escrow = new VotingEscrow(address(FLOW), address(artProxy), owners[0]);

        deployPairFactoryAndRouter();
        voter = new Voter(
            address(escrow),
            address(factory),
            address(gaugeFactory),
            address(bribeFactory)
        );
        factory.setVoter(address(voter));
        flowDaiPair = Pair(
            factory.createPair(address(FLOW), address(DAI), false)
        );

        deployOptionTokenV3WithOwner(
            address(owner),
            address(gaugeFactory),
            address(voter),
            address(escrow)
        );
        gaugeFactory.setOFlow(address(oFlowV3));

        lpHelper = new LpHelper(
            address(router),
            address(voter),
            address(factory),
            owners[0]
        );
    }

    function testDepositAndStakeInGaugeForWithoutGauge() public {
        vm.startPrank(address(owner));
        washTrades();

        FLOW.approve(address(lpHelper), 1000);
        DAI.approve(address(lpHelper), 1000);

        uint256 ownerFlowBalanceBefore = FLOW.balanceOf(address(owner));
        uint256 ownerDaiBalanceBefore = DAI.balanceOf(address(owner));
        uint256 pairFlowBalanceBefore = FLOW.balanceOf(address(flowDaiPair));
        uint256 pairDaiBalanceBefore = DAI.balanceOf(address(flowDaiPair));

        lpHelper.depositAndStakeInGaugeFor(
            address(owner2),
            address(FLOW),
            address(DAI),
            false,
            1000,
            1000,
            1,
            1,
            block.timestamp
        );
        vm.stopPrank();

        uint256 ownerFlowBalanceAfter = FLOW.balanceOf(address(owner));
        uint256 ownerDaiBalanceAfter = DAI.balanceOf(address(owner));
        uint256 pairFlowBalanceAfter = FLOW.balanceOf(address(flowDaiPair));
        uint256 pairDaiBalanceAfter = DAI.balanceOf(address(flowDaiPair));

        assertEq(
            ownerFlowBalanceBefore - ownerFlowBalanceAfter,
            pairFlowBalanceAfter - pairFlowBalanceBefore
        );
        assertEq(
            ownerDaiBalanceBefore - ownerDaiBalanceAfter,
            pairDaiBalanceAfter - pairDaiBalanceBefore
        );
        assertGt(flowDaiPair.balanceOf(address(owner)), 0);
    }

    function testDepositAndStakeInGaugeForWithGauge() public {
        vm.startPrank(address(owner));
        washTrades();

        gauge = GaugeV4(voter.createGauge(address(flowDaiPair), 0));
        oFlowV3.updateGauge();

        uint256 ownerFlowBalanceBefore = FLOW.balanceOf(address(owner));
        uint256 ownerDaiBalanceBefore = DAI.balanceOf(address(owner));
        uint256 pairFlowBalanceBefore = FLOW.balanceOf(address(flowDaiPair));
        uint256 pairDaiBalanceBefore = DAI.balanceOf(address(flowDaiPair));

        uint256 gaugeDepositedBalanceBefore = gauge.balanceOf(address(owner2));

        FLOW.approve(address(lpHelper), 1000);
        DAI.approve(address(lpHelper), 1000);

        lpHelper.depositAndStakeInGaugeFor(
            address(owner2),
            address(FLOW),
            address(DAI),
            false,
            1000,
            1000,
            1,
            1,
            block.timestamp
        );
        vm.stopPrank();

        uint256 ownerFlowBalanceAfter = FLOW.balanceOf(address(owner));
        uint256 ownerDaiBalanceAfter = DAI.balanceOf(address(owner));
        uint256 pairFlowBalanceAfter = FLOW.balanceOf(address(flowDaiPair));
        uint256 pairDaiBalanceAfter = DAI.balanceOf(address(flowDaiPair));

        uint256 gaugeDepositedBalanceAfter = FLOW.balanceOf(address(owner2));

        assertEq(
            ownerFlowBalanceBefore - ownerFlowBalanceAfter,
            pairFlowBalanceAfter - pairFlowBalanceBefore
        );
        assertEq(
            ownerDaiBalanceBefore - ownerDaiBalanceAfter,
            pairDaiBalanceAfter - pairDaiBalanceBefore
        );
        assertGt(gaugeDepositedBalanceAfter - gaugeDepositedBalanceBefore, 0);
    }

    function testOwnerCanSetPairfactory() public {
        vm.startPrank(address(owner));
        vm.expectEmit(true, true, false, false);
        emit PairFactorySet(address(0x01));
        lpHelper.setPairFactory(address(0x01));
        vm.stopPrank();

        assertEq(lpHelper.pairFactory(), address(0x01));
    }

    function testNonOwnerCannotSetPairfactory() public {
        vm.startPrank(address(owner2));
        vm.expectRevert("Ownable: caller is not the owner");
        lpHelper.setPairFactory(address(0x01));
        vm.stopPrank();
    }

    function testOwnerCanSetRouter() public {
        vm.startPrank(address(owner));
        vm.expectEmit(true, true, false, false);
        emit RouterSet(address(0x01));
        lpHelper.setRouter(address(0x01));
        vm.stopPrank();

        assertEq(lpHelper.router(), address(0x01));
    }

    function testNonOwnerCannotSetRouter() public {
        vm.startPrank(address(owner2));
        vm.expectRevert("Ownable: caller is not the owner");
        lpHelper.setRouter(address(0x01));
        vm.stopPrank();
    }

    function testPauseAndUnpause() public {
        vm.startPrank(address(owner));
        washTrades();

        vm.expectEmit(true, false, false, false);
        emit PauseStateChanged(true);
        lpHelper.pause();
        FLOW.approve(address(lpHelper), 1000);
        DAI.approve(address(lpHelper), 1000);

        vm.expectRevert(LpHelper_Paused.selector);
        lpHelper.depositAndStakeInGaugeFor(
            address(owner2),
            address(FLOW),
            address(DAI),
            false,
            1000,
            1000,
            1,
            1,
            block.timestamp
        );

        vm.expectEmit(true, false, false, false);
        emit PauseStateChanged(false);
        lpHelper.unPause();
        lpHelper.depositAndStakeInGaugeFor(
            address(owner2),
            address(FLOW),
            address(DAI),
            false,
            1000,
            1000,
            1,
            1,
            block.timestamp
        );
        vm.stopPrank();
    }

    function testNonOwnerCannotPause() public {
        vm.startPrank(address(owner2));
        vm.expectRevert("Ownable: caller is not the owner");
        lpHelper.pause();
        vm.stopPrank();
    }

    function testNonOwnerCannotUnpause() public {
        vm.startPrank(address(owner));
        lpHelper.pause();
        vm.stopPrank();

        vm.startPrank(address(owner2));
        vm.expectRevert("Ownable: caller is not the owner");
        lpHelper.unPause();
        vm.stopPrank();
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

    // function testExercise() public {
    //     vm.startPrank(address(owner));
    //     FLOW.approve(address(oFlowV3), TOKEN_1);
    //     // mint Option token to owner 2
    //     oFlowV3.mint(address(owner2), TOKEN_1);

    //     oFlowV3.setTreasury(address(owner), address(owner3));
    //     washTrades();
    //     vm.stopPrank();

    //     uint256 flowBalanceBefore = FLOW.balanceOf(address(owner2));
    //     uint256 oFlowV3BalanceBefore = oFlowV3.balanceOf(address(owner2));
    //     uint256 daiBalanceBefore = DAI.balanceOf(address(owner2));
    //     uint256 treasuryDaiBalanceBefore = DAI.balanceOf(address(owner));
    //     uint256 treasuryVMDaiBalanceBefore = DAI.balanceOf(address(owner3));
    //     uint256 rewardpairDaiBalanceBefore = DAI.balanceOf(address(gauge));

    //     uint256 discountedPrice = oFlowV3.getDiscountedPrice(TOKEN_1);

    //     vm.startPrank(address(owner2));
    //     DAI.approve(address(oFlowV3), TOKEN_100K);
    //     vm.expectEmit(true, true, false, true);
    //     emit Exercise(
    //         address(owner2),
    //         address(owner2),
    //         TOKEN_1,
    //         discountedPrice
    //     );
    //     oFlowV3.exercise(TOKEN_1, TOKEN_1, address(owner2));
    //     vm.stopPrank();

    //     uint256 flowBalanceAfter = FLOW.balanceOf(address(owner2));
    //     uint256 oFlowV3BalanceAfter = oFlowV3.balanceOf(address(owner2));
    //     uint256 daiBalanceAfter = DAI.balanceOf(address(owner2));
    //     uint256 treasuryDaiBalanceAfter = DAI.balanceOf(address(owner));
    //     uint256 treasuryVMDaiBalanceAfter = DAI.balanceOf(address(owner3));
    //     uint256 rewardGaugeDaiAfter = DAI.balanceOf(address(gauge));

    //     assertEq(flowBalanceAfter - flowBalanceBefore, TOKEN_1);
    //     assertEq(oFlowV3BalanceBefore - oFlowV3BalanceAfter, TOKEN_1);
    //     assertEq(daiBalanceBefore - daiBalanceAfter, discountedPrice);
    //     assertEq(
    //         (rewardGaugeDaiAfter - rewardpairDaiBalanceBefore) +
    //             (treasuryDaiBalanceAfter - treasuryDaiBalanceBefore) +
    //             (treasuryVMDaiBalanceAfter - treasuryVMDaiBalanceBefore),
    //         discountedPrice
    //     );
    // }

    // function testExerciseFewTimes() public {
    //     vm.startPrank(address(owner));

    //     uint256 amountOfExercise = 4;
    //     FLOW.approve(address(oFlowV3), TOKEN_1 * amountOfExercise);
    //     // mint Option token to owner 2
    //     oFlowV3.mint(address(owner2), TOKEN_1 * amountOfExercise);

    //     washTrades();
    //     vm.stopPrank();

    //     uint256 flowBalanceBefore = FLOW.balanceOf(address(owner2));
    //     uint256 oFlowV3BalanceBefore = oFlowV3.balanceOf(address(owner2));
    //     uint256 daiBalanceBefore = DAI.balanceOf(address(owner2));
    //     uint256 treasuryDaiBalanceBefore = DAI.balanceOf(address(owner));
    //     uint256 rewardpairDaiBalanceBefore = DAI.balanceOf(address(gauge));

    //     uint256 discountedPrice = oFlowV3.getDiscountedPrice(TOKEN_1);

    //     vm.startPrank(address(owner2));
    //     DAI.approve(address(oFlowV3), TOKEN_100K);
    //     vm.expectEmit(true, true, false, true);
    //     emit Exercise(
    //         address(owner2),
    //         address(owner2),
    //         TOKEN_1,
    //         discountedPrice
    //     );
    //     oFlowV3.exercise(TOKEN_1, TOKEN_1, address(owner2));
    //     oFlowV3.exercise(TOKEN_1, TOKEN_1, address(owner2));
    //     oFlowV3.exercise(TOKEN_1, TOKEN_1, address(owner2));
    //     oFlowV3.exercise(TOKEN_1, TOKEN_1, address(owner2));

    //     vm.stopPrank();

    //     uint256 flowBalanceAfter = FLOW.balanceOf(address(owner2));
    //     uint256 oFlowV3BalanceAfter = oFlowV3.balanceOf(address(owner2));
    //     uint256 daiBalanceAfter = DAI.balanceOf(address(owner2));
    //     uint256 treasuryDaiBalanceAfter = DAI.balanceOf(address(owner));
    //     uint256 rewardGaugeDaiAfter = DAI.balanceOf(address(gauge));

    //     assertEq(
    //         flowBalanceAfter - flowBalanceBefore,
    //         TOKEN_1 * amountOfExercise
    //     );
    //     assertEq(
    //         oFlowV3BalanceBefore - oFlowV3BalanceAfter,
    //         TOKEN_1 * amountOfExercise
    //     );
    //     assertEq(
    //         daiBalanceBefore - daiBalanceAfter,
    //         discountedPrice * amountOfExercise
    //     );
    //     assertEq(
    //         (rewardGaugeDaiAfter - rewardpairDaiBalanceBefore) +
    //             (treasuryDaiBalanceAfter - treasuryDaiBalanceBefore),
    //         discountedPrice * amountOfExercise
    //     );
    // }

    // function testCannotExercisePastDeadline() public {
    //     vm.startPrank(address(owner));
    //     FLOW.approve(address(oFlowV3), TOKEN_1);
    //     oFlowV3.mint(address(owner), TOKEN_1);

    //     DAI.approve(address(oFlowV3), TOKEN_100K);
    //     vm.expectRevert(OptionToken_PastDeadline.selector);
    //     oFlowV3.exercise(TOKEN_1, TOKEN_1, address(owner), block.timestamp - 1);
    //     vm.stopPrank();
    // }

    // function testCannotExerciseWithSlippageTooHigh() public {
    //     vm.startPrank(address(owner));
    //     FLOW.approve(address(oFlowV3), TOKEN_1);
    //     oFlowV3.mint(address(owner), TOKEN_1);

    //     washTrades();
    //     uint256 discountedPrice = oFlowV3.getDiscountedPrice(TOKEN_1);

    //     DAI.approve(address(oFlowV3), TOKEN_100K);
    //     vm.expectRevert(OptionToken_SlippageTooHigh.selector);
    //     oFlowV3.exercise(TOKEN_1, discountedPrice - 1, address(owner));
    //     vm.stopPrank();
    // }

    // function testExerciseVe() public {
    //     vm.startPrank(address(owner));
    //     FLOW.approve(address(oFlowV3), TOKEN_1);
    //     // mint Option token to owner 2
    //     oFlowV3.mint(address(owner2), TOKEN_1);

    //     washTrades();
    //     vm.stopPrank();

    //     uint256 nftBalanceBefore = escrow.balanceOf(address(owner2));
    //     uint256 oFlowV3BalanceBefore = oFlowV3.balanceOf(address(owner2));
    //     uint256 daiBalanceBefore = DAI.balanceOf(address(owner2));
    //     uint256 treasuryDaiBalanceBefore = DAI.balanceOf(address(owner));
    //     uint256 rewardpairDaiBalanceBefore = DAI.balanceOf(address(gauge));

    //     uint256 discountedPrice = oFlowV3.getVeDiscountedPrice(TOKEN_1);

    //     vm.startPrank(address(owner2));
    //     DAI.approve(address(oFlowV3), TOKEN_100K);
    //     vm.expectEmit(true, true, false, true);
    //     emit ExerciseVe(
    //         address(owner2),
    //         address(owner2),
    //         TOKEN_1,
    //         discountedPrice,
    //         escrow.currentTokenId() + 1
    //     );
    //     (, uint256 nftId) = oFlowV3.exerciseVe(
    //         TOKEN_1,
    //         TOKEN_1,
    //         address(owner2),
    //         block.timestamp
    //     );
    //     vm.stopPrank();

    //     uint256 nftBalanceAfter = escrow.balanceOf(address(owner2));
    //     uint256 oFlowV3BalanceAfter = oFlowV3.balanceOf(address(owner2));
    //     uint256 daiBalanceAfter = DAI.balanceOf(address(owner2));
    //     uint256 treasuryDaiBalanceAfter = DAI.balanceOf(address(owner));
    //     uint256 rewardGaugeDaiAfter = DAI.balanceOf(address(gauge));

    //     assertEq(nftBalanceAfter - nftBalanceBefore, 1);
    //     assertEq(oFlowV3BalanceBefore - oFlowV3BalanceAfter, TOKEN_1);
    //     assertEq(daiBalanceBefore - daiBalanceAfter, discountedPrice);
    //     assertEq(
    //         (rewardGaugeDaiAfter - rewardpairDaiBalanceBefore) +
    //             (treasuryDaiBalanceAfter - treasuryDaiBalanceBefore),
    //         discountedPrice
    //     );
    //     assertGt(escrow.balanceOfNFT(nftId), 0);
    // }

    // function testExerciseLp() public {
    //     vm.startPrank(address(owner));
    //     FLOW.approve(address(oFlowV3), TOKEN_1);
    //     // mint Option token to owner 2
    //     oFlowV3.mint(address(owner2), TOKEN_1);

    //     washTrades();
    //     vm.stopPrank();
    //     uint256 flowBalanceBefore = FLOW.balanceOf(address(owner2));
    //     uint256 oFlowV3BalanceBefore = oFlowV3.balanceOf(address(owner2));
    //     uint256 daiBalanceBefore = DAI.balanceOf(address(owner2));
    //     uint256 treasuryDaiBalanceBefore = DAI.balanceOf(address(owner));
    //     uint256 rewardpairDaiBalanceBefore = DAI.balanceOf(address(gauge));

    //     (uint256 underlyingReserve, uint256 paymentReserve) = IRouter(router)
    //         .getReserves(address(FLOW), address(DAI), false);
    //     uint256 paymentAmountToAddLiquidity = (TOKEN_1 * paymentReserve) /
    //         underlyingReserve;

    //     uint256 discountedPrice = oFlowV3.getLpDiscountedPrice(TOKEN_1, 20);

    //     vm.startPrank(address(owner2));
    //     DAI.approve(address(oFlowV3), TOKEN_100K);
    //     vm.expectEmit(true, true, false, true);
    //     emit ExerciseLp(
    //         address(owner2),
    //         address(owner2),
    //         TOKEN_1,
    //         discountedPrice,
    //         1000000000999700046
    //     );

    //     oFlowV3.exerciseLp(
    //         TOKEN_1,
    //         TOKEN_1,
    //         address(owner2),
    //         20,
    //         block.timestamp
    //     );
    //     vm.stopPrank();

    //     uint256 flowBalanceAfter = FLOW.balanceOf(address(owner2));
    //     uint256 oFlowV3BalanceAfter = oFlowV3.balanceOf(address(owner2));
    //     uint256 daiBalanceAfter = DAI.balanceOf(address(owner2));
    //     uint256 treasuryDaiBalanceAfter = DAI.balanceOf(address(owner));
    //     uint256 rewardGaugeDaiAfter = DAI.balanceOf(address(gauge));

    //     assertEq(
    //         gauge.lockEnd(address(owner2)),
    //         block.timestamp + 52 * 7 * 86400
    //     );

    //     assertEq(flowBalanceAfter - flowBalanceBefore, 0);
    //     assertEq(oFlowV3BalanceBefore - oFlowV3BalanceAfter, TOKEN_1);
    //     assertEq(
    //         daiBalanceBefore - daiBalanceAfter,
    //         discountedPrice + paymentAmountToAddLiquidity
    //     );
    //     assertEq(
    //         (rewardGaugeDaiAfter - rewardpairDaiBalanceBefore) +
    //             (treasuryDaiBalanceAfter - treasuryDaiBalanceBefore),
    //         discountedPrice
    //     );
    // }
}
