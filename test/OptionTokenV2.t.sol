// 1:1 with Hardhat test
pragma solidity 0.8.13;

import "./BaseTest.sol";

contract OptionTokenV2Test is BaseTest {
    GaugeFactory gaugeFactory;
    VotingEscrow escrow;

    error OptionToken_InvalidDiscount();
    error OptionToken_Paused();
    error OptionToken_NoAdminRole();
    error OptionToken_NoMinterRole();
    error OptionToken_NoPauserRole();
    error OptionToken_IncorrectPairToken();
    error OptionToken_InvalidTwapPoints();
    error OptionToken_SlippageTooHigh();
    error OptionToken_PastDeadline();

    event Exercise(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 paymentAmount
    );
    event ExerciseVe(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 paymentAmount,
        uint256 nftId
    );
    event SetPairAndPaymentToken(
        IPair indexed newPair,
        address indexed newPaymentToken
    );
    event SetTreasury(address indexed newTreasury);
    event SetDiscount(uint256 discount);
    event SetVeDiscount(uint256 veDiscount);
    event PauseStateChanged(bool isPaused);
    event SetTwapPoints(uint256 twapPoints);

    function setUp() public {
        deployOwners();
        deployCoins();
        mintStables();
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1e27;
        amounts[1] = 1e27;
        amounts[2] = 1e27;
        mintFlow(owners, amounts);

        gaugeFactory = new GaugeFactory();
        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(FLOW), address(artProxy), owners[0]);
        deployPairFactoryAndRouter();
        flowDaiPair = Pair(
            factory.createPair(address(FLOW), address(DAI), false)
        );
        deployOptionTokenV2WithOwner(
            address(owner),
            address(gaugeFactory),
            address(escrow)
        );
    }

    function testAdminCanSetPairAndPaymentToken() public {
        address flowFraxPair = factory.createPair(
            address(FLOW),
            address(FRAX),
            false
        );
        vm.startPrank(address(owner));
        vm.expectEmit(true, true, false, false);
        emit SetPairAndPaymentToken(IPair(flowFraxPair), address(FRAX));
        oFlowV2.setPairAndPaymentToken(IPair(flowFraxPair), address(FRAX));
        vm.stopPrank();
    }

    function testNonAdminCannotSetPairAndPaymentToken() public {
        address flowFraxPair = factory.createPair(
            address(FLOW),
            address(FRAX),
            false
        );
        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        oFlowV2.setPairAndPaymentToken(IPair(flowFraxPair), address(FRAX));
        vm.stopPrank();
    }

    function testCannotSetIncorrectPairToken() public {
        address daiFraxPair = factory.createPair(
            address(DAI),
            address(FRAX),
            false
        );
        vm.startPrank(address(owner));
        vm.expectRevert(OptionToken_IncorrectPairToken.selector);
        oFlowV2.setPairAndPaymentToken(IPair(daiFraxPair), address(DAI));
        vm.stopPrank();
    }

    function testSetTreasury() public {
        vm.startPrank(address(owner));
        assertEq(oFlowV2.treasury(), address(owner));
        vm.expectEmit(true, false, false, false);
        emit SetTreasury(address(owner2));
        oFlowV2.setTreasury(address(owner2));
        assertEq(oFlowV2.treasury(), address(owner2));
        vm.stopPrank();
    }

    function testNonAdminCannotSetTreasury() public {
        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        oFlowV2.setTreasury(address(owner2));
        vm.stopPrank();
    }

    function testSetDiscount() public {
        vm.startPrank(address(owner));
        assertEq(oFlowV2.discount(), 30);
        vm.expectEmit(true, false, false, false);
        emit SetDiscount(50);
        oFlowV2.setDiscount(50);
        assertEq(oFlowV2.discount(), 50);
        vm.stopPrank();
    }

    function testNonAdminCannotSetDiscount() public {
        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        oFlowV2.setDiscount(50);
        vm.stopPrank();
    }

    function testSetVeDiscount() public {
        vm.startPrank(address(owner));
        assertEq(oFlowV2.veDiscount(), 60);
        vm.expectEmit(true, false, false, false);
        emit SetVeDiscount(50);
        oFlowV2.setVeDiscount(50);
        assertEq(oFlowV2.veDiscount(), 50);
        vm.stopPrank();
    }

    function testNonAdminCannotSetVeDiscount() public {
        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        oFlowV2.setVeDiscount(50);
        vm.stopPrank();
    }

    function testCannotSetDiscountOutOfBoundry() public {
        vm.startPrank(address(owner));
        vm.expectRevert(OptionToken_InvalidDiscount.selector);
        oFlowV2.setDiscount(101);
        vm.expectRevert(OptionToken_InvalidDiscount.selector);
        oFlowV2.setDiscount(0);
        vm.stopPrank();
    }

    function testSetTwapPoints() public {
        vm.startPrank(address(owner));
        assertEq(oFlowV2.twapPoints(), 4);
        vm.expectEmit(true, false, false, false);
        emit SetTwapPoints(15);
        oFlowV2.setTwapPoints(15);
        assertEq(oFlowV2.twapPoints(), 15);
        vm.stopPrank();
    }

    function testNonAdminCannotSetTwapPoints() public {
        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        oFlowV2.setTwapPoints(15);
        vm.stopPrank();
    }

    function testCannotSetTwapPointsOutOfBoundry() public {
        vm.startPrank(address(owner));
        vm.expectRevert(OptionToken_InvalidTwapPoints.selector);
        oFlowV2.setTwapPoints(51);
        vm.expectRevert(OptionToken_InvalidTwapPoints.selector);
        oFlowV2.setTwapPoints(0);
        vm.stopPrank();
    }

    function testMintAndBurn() public {
        uint256 flowBalanceBefore = FLOW.balanceOf(address(owner));
        uint256 oFlowV2BalanceBefore = oFlowV2.balanceOf(address(owner));

        vm.startPrank(address(owner));
        FLOW.approve(address(oFlowV2), TOKEN_1);
        oFlowV2.mint(address(owner), TOKEN_1);
        vm.stopPrank();

        uint256 flowBalanceAfter = FLOW.balanceOf(address(owner));
        uint256 oFlowV2BalanceAfter = oFlowV2.balanceOf(address(owner));

        assertEq(flowBalanceBefore - flowBalanceAfter, TOKEN_1);
        assertEq(oFlowV2BalanceAfter - oFlowV2BalanceBefore, TOKEN_1);

        vm.startPrank(address(owner));
        oFlowV2.burn(TOKEN_1);
        vm.stopPrank();

        uint256 flowBalanceAfter_ = FLOW.balanceOf(address(owner));
        uint256 oFlowV2BalanceAfter_ = oFlowV2.balanceOf(address(owner));

        assertEq(flowBalanceAfter_ - flowBalanceAfter, TOKEN_1);
        assertEq(oFlowV2BalanceAfter - oFlowV2BalanceAfter_, TOKEN_1);
    }

    function testNonMinterCannotMint() public {
        vm.startPrank(address(owner2));
        FLOW.approve(address(oFlowV2), TOKEN_1);
        vm.expectRevert(OptionToken_NoMinterRole.selector);
        oFlowV2.mint(address(owner2), TOKEN_1);
        vm.stopPrank();
    }

    function testNonAdminCannotBurn() public {
        vm.startPrank(address(owner));
        FLOW.approve(address(oFlowV2), TOKEN_1);
        oFlowV2.mint(address(owner2), TOKEN_1);
        vm.stopPrank();

        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        oFlowV2.burn(TOKEN_1);
        vm.stopPrank();
    }

    function testPauseAndUnpause() public {
        vm.startPrank(address(owner));

        FLOW.approve(address(oFlowV2), TOKEN_1);
        oFlowV2.mint(address(owner), TOKEN_1);

        washTrades();

        vm.expectEmit(true, false, false, false);
        emit PauseStateChanged(true);
        oFlowV2.pause();
        vm.expectRevert(OptionToken_Paused.selector);
        oFlowV2.exercise(TOKEN_1, TOKEN_1, address(owner));

        vm.expectEmit(true, false, false, false);
        emit PauseStateChanged(false);
        oFlowV2.unPause();
        DAI.approve(address(oFlowV2), TOKEN_100K);
        oFlowV2.exercise(TOKEN_1, TOKEN_1, address(owner));
        vm.stopPrank();
    }

    function testNonPauserCannotPause() public {
        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoPauserRole.selector);
        oFlowV2.pause();
        vm.stopPrank();
    }

    function testNonAdminCannotUnpause() public {
        vm.startPrank(address(owner));
        oFlowV2.pause();
        vm.stopPrank();

        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        oFlowV2.unPause();
        vm.stopPrank();
    }

    function washTrades() public {
        FLOW.approve(address(router), TOKEN_100K);
        DAI.approve(address(router), TOKEN_100K);
        router.addLiquidity(
            address(FLOW),
            address(DAI),
            false,
            address(factory),
            TOKEN_100K,
            TOKEN_100K,
            0,
            0,
            address(owner),
            block.timestamp
        );

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(FLOW), address(DAI), false, address(factory));
        Router.route[] memory routes2 = new Router.route[](1);
        routes2[0] = Router.route(address(DAI), address(FLOW), false, address(factory));

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

    function testExercise() public {
        vm.startPrank(address(owner));
        FLOW.approve(address(oFlowV2), TOKEN_1);
        // mint Option token to owner 2
        oFlowV2.mint(address(owner2), TOKEN_1);

        washTrades();
        vm.stopPrank();

        uint256 flowBalanceBefore = FLOW.balanceOf(address(owner2));
        uint256 oFlowV2BalanceBefore = oFlowV2.balanceOf(address(owner2));
        uint256 daiBalanceBefore = DAI.balanceOf(address(owner2));
        uint256 treasuryDaiBalanceBefore = DAI.balanceOf(address(owner));

        uint256 discountedPrice = oFlowV2.getDiscountedPrice(TOKEN_1);

        vm.startPrank(address(owner2));
        DAI.approve(address(oFlowV2), TOKEN_100K);
        vm.expectEmit(true, true, false, true);
        emit Exercise(
            address(owner2),
            address(owner2),
            TOKEN_1,
            discountedPrice
        );
        oFlowV2.exercise(TOKEN_1, TOKEN_1, address(owner2));
        vm.stopPrank();

        uint256 flowBalanceAfter = FLOW.balanceOf(address(owner2));
        uint256 oFlowV2BalanceAfter = oFlowV2.balanceOf(address(owner2));
        uint256 daiBalanceAfter = DAI.balanceOf(address(owner2));
        uint256 treasuryDaiBalanceAfter = DAI.balanceOf(address(owner));

        assertEq(flowBalanceAfter - flowBalanceBefore, TOKEN_1);
        assertEq(oFlowV2BalanceBefore - oFlowV2BalanceAfter, TOKEN_1);
        assertEq(daiBalanceBefore - daiBalanceAfter, discountedPrice);
        assertEq(
            treasuryDaiBalanceAfter - treasuryDaiBalanceBefore,
            discountedPrice
        );
    }

    function testCannotExercisePastDeadline() public {
        vm.startPrank(address(owner));
        FLOW.approve(address(oFlowV2), TOKEN_1);
        oFlowV2.mint(address(owner), TOKEN_1);

        DAI.approve(address(oFlowV2), TOKEN_100K);
        vm.expectRevert(OptionToken_PastDeadline.selector);
        oFlowV2.exercise(TOKEN_1, TOKEN_1, address(owner), block.timestamp - 1);
        vm.stopPrank();
    }

    function testCannotExerciseWithSlippageTooHigh() public {
        vm.startPrank(address(owner));
        FLOW.approve(address(oFlowV2), TOKEN_1);
        oFlowV2.mint(address(owner), TOKEN_1);

        washTrades();
        uint256 discountedPrice = oFlowV2.getDiscountedPrice(TOKEN_1);

        DAI.approve(address(oFlowV2), TOKEN_100K);
        vm.expectRevert(OptionToken_SlippageTooHigh.selector);
        oFlowV2.exercise(TOKEN_1, discountedPrice - 1, address(owner));
        vm.stopPrank();
    }

    function testExerciseVe() public {
        vm.startPrank(address(owner));
        FLOW.approve(address(oFlowV2), TOKEN_1);
        // mint Option token to owner 2
        oFlowV2.mint(address(owner2), TOKEN_1);

        washTrades();
        vm.stopPrank();

        uint256 nftBalanceBefore = escrow.balanceOf(address(owner2));
        uint256 oFlowV2BalanceBefore = oFlowV2.balanceOf(address(owner2));
        uint256 daiBalanceBefore = DAI.balanceOf(address(owner2));
        uint256 treasuryDaiBalanceBefore = DAI.balanceOf(address(owner));

        uint256 discountedPrice = oFlowV2.getVeDiscountedPrice(TOKEN_1);

        vm.startPrank(address(owner2));
        DAI.approve(address(oFlowV2), TOKEN_100K);
        vm.expectEmit(true, true, false, true);
        emit ExerciseVe(
            address(owner2),
            address(owner2),
            TOKEN_1,
            discountedPrice,
            escrow.currentTokenId() + 1
        );
        (, uint256 nftId) = oFlowV2.exerciseVe(
            TOKEN_1,
            TOKEN_1,
            address(owner2),
            block.timestamp
        );
        vm.stopPrank();

        uint256 nftBalanceAfter = escrow.balanceOf(address(owner2));
        uint256 oFlowV2BalanceAfter = oFlowV2.balanceOf(address(owner2));
        uint256 daiBalanceAfter = DAI.balanceOf(address(owner2));
        uint256 treasuryDaiBalanceAfter = DAI.balanceOf(address(owner));

        assertEq(nftBalanceAfter - nftBalanceBefore, 1);
        assertEq(oFlowV2BalanceBefore - oFlowV2BalanceAfter, TOKEN_1);
        assertEq(daiBalanceBefore - daiBalanceAfter, discountedPrice);
        assertEq(
            treasuryDaiBalanceAfter - treasuryDaiBalanceBefore,
            discountedPrice
        );
        assertGt(escrow.balanceOfNFT(nftId), 0);
    }
}
