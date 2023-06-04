// 1:1 with Hardhat test
pragma solidity 0.8.13;

import "./BaseTest.sol";

contract OptionTokenTest is BaseTest {
    GaugeFactory gaugeFactory;

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
    event SetPairAndPaymentToken(
        IPair indexed newPair,
        address indexed newPaymentToken
    );
    event SetTreasury(address indexed newTreasury);
    event SetDiscount(uint256 discount);
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
        deployPairFactoryAndRouter();
        flowDaiPair = Pair(
            factory.createPair(address(FLOW), address(DAI), false)
        );
        deployOptionTokenWithOwner(address(owner), address(gaugeFactory));
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
        oFlow.setPairAndPaymentToken(IPair(flowFraxPair), address(FRAX));
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
        oFlow.setPairAndPaymentToken(IPair(flowFraxPair), address(FRAX));
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
        oFlow.setPairAndPaymentToken(IPair(daiFraxPair), address(DAI));
        vm.stopPrank();
    }

    function testSetTreasury() public {
        vm.startPrank(address(owner));
        assertEq(oFlow.treasury(), address(owner));
        vm.expectEmit(true, false, false, false);
        emit SetTreasury(address(owner2));
        oFlow.setTreasury(address(owner2));
        assertEq(oFlow.treasury(), address(owner2));
        vm.stopPrank();
    }

    function testNonAdminCannotSetTreasury() public {
        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        oFlow.setTreasury(address(owner2));
        vm.stopPrank();
    }

    function testSetDiscount() public {
        vm.startPrank(address(owner));
        assertEq(oFlow.discount(), 30);
        vm.expectEmit(true, false, false, false);
        emit SetDiscount(50);
        oFlow.setDiscount(50);
        assertEq(oFlow.discount(), 50);
        vm.stopPrank();
    }

    function testNonAdminCannotSetDiscount() public {
        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        oFlow.setDiscount(50);
        vm.stopPrank();
    }

    function testCannotSetDiscountOutOfBoundry() public {
        vm.startPrank(address(owner));
        vm.expectRevert(OptionToken_InvalidDiscount.selector);
        oFlow.setDiscount(101);
        vm.expectRevert(OptionToken_InvalidDiscount.selector);
        oFlow.setDiscount(0);
        vm.stopPrank();
    }

    function testSetTwapPoints() public {
        vm.startPrank(address(owner));
        assertEq(oFlow.twapPoints(), 4);
        vm.expectEmit(true, false, false, false);
        emit SetTwapPoints(15);
        oFlow.setTwapPoints(15);
        assertEq(oFlow.twapPoints(), 15);
        vm.stopPrank();
    }

    function testNonAdminCannotSetTwapPoints() public {
        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        oFlow.setTwapPoints(15);
        vm.stopPrank();
    }

    function testCannotSetTwapPointsOutOfBoundry() public {
        vm.startPrank(address(owner));
        vm.expectRevert(OptionToken_InvalidTwapPoints.selector);
        oFlow.setTwapPoints(51);
        vm.expectRevert(OptionToken_InvalidTwapPoints.selector);
        oFlow.setTwapPoints(0);
        vm.stopPrank();
    }

    function testMintAndBurn() public {
        uint256 flowBalanceBefore = FLOW.balanceOf(address(owner));
        uint256 oFlowBalanceBefore = oFlow.balanceOf(address(owner));

        vm.startPrank(address(owner));
        FLOW.approve(address(oFlow), TOKEN_1);
        oFlow.mint(address(owner), TOKEN_1);
        vm.stopPrank();

        uint256 flowBalanceAfter = FLOW.balanceOf(address(owner));
        uint256 oFlowBalanceAfter = oFlow.balanceOf(address(owner));

        assertEq(flowBalanceBefore - flowBalanceAfter, TOKEN_1);
        assertEq(oFlowBalanceAfter - oFlowBalanceBefore, TOKEN_1);

        vm.startPrank(address(owner));
        oFlow.burn(TOKEN_1);
        vm.stopPrank();

        uint256 flowBalanceAfter_ = FLOW.balanceOf(address(owner));
        uint256 oFlowBalanceAfter_ = oFlow.balanceOf(address(owner));

        assertEq(flowBalanceAfter_ - flowBalanceAfter, TOKEN_1);
        assertEq(oFlowBalanceAfter - oFlowBalanceAfter_, TOKEN_1);
    }

    function testNonMinterCannotMint() public {
        vm.startPrank(address(owner2));
        FLOW.approve(address(oFlow), TOKEN_1);
        vm.expectRevert(OptionToken_NoMinterRole.selector);
        oFlow.mint(address(owner2), TOKEN_1);
        vm.stopPrank();
    }

    function testNonAdminCannotBurn() public {
        vm.startPrank(address(owner));
        FLOW.approve(address(oFlow), TOKEN_1);
        oFlow.mint(address(owner2), TOKEN_1);
        vm.stopPrank();

        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        oFlow.burn(TOKEN_1);
        vm.stopPrank();
    }

    function testPauseAndUnpause() public {
        vm.startPrank(address(owner));

        FLOW.approve(address(oFlow), TOKEN_1);
        oFlow.mint(address(owner), TOKEN_1);

        washTrades();

        vm.expectEmit(true, false, false, false);
        emit PauseStateChanged(true);
        oFlow.pause();
        vm.expectRevert(OptionToken_Paused.selector);
        oFlow.exercise(TOKEN_1, TOKEN_1, address(owner));

        vm.expectEmit(true, false, false, false);
        emit PauseStateChanged(false);
        oFlow.unPause();
        DAI.approve(address(oFlow), TOKEN_100K);
        oFlow.exercise(TOKEN_1, TOKEN_1, address(owner));
        vm.stopPrank();
    }

    function testNonPauserCannotPause() public {
        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoPauserRole.selector);
        oFlow.pause();
        vm.stopPrank();
    }

    function testNonAdminCannotUnpause() public {
        vm.startPrank(address(owner));
        oFlow.pause();
        vm.stopPrank();

        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        oFlow.unPause();
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

    function testExercise() public {
        vm.startPrank(address(owner));
        FLOW.approve(address(oFlow), TOKEN_1);
        // mint Option token to owner 2
        oFlow.mint(address(owner2), TOKEN_1);

        washTrades();
        vm.stopPrank();

        uint256 flowBalanceBefore = FLOW.balanceOf(address(owner2));
        uint256 oFlowBalanceBefore = oFlow.balanceOf(address(owner2));
        uint256 daiBalanceBefore = DAI.balanceOf(address(owner2));
        uint256 treasuryDaiBalanceBefore = DAI.balanceOf(address(owner));

        uint256 discountedPrice = oFlow.getDiscountedPrice(TOKEN_1);

        vm.startPrank(address(owner2));
        DAI.approve(address(oFlow), TOKEN_100K);
        vm.expectEmit(true, true, false, true);
        emit Exercise(
            address(owner2),
            address(owner2),
            TOKEN_1,
            discountedPrice
        );
        oFlow.exercise(TOKEN_1, TOKEN_1, address(owner2));
        vm.stopPrank();

        uint256 flowBalanceAfter = FLOW.balanceOf(address(owner2));
        uint256 oFlowBalanceAfter = oFlow.balanceOf(address(owner2));
        uint256 daiBalanceAfter = DAI.balanceOf(address(owner2));
        uint256 treasuryDaiBalanceAfter = DAI.balanceOf(address(owner));

        assertEq(flowBalanceAfter - flowBalanceBefore, TOKEN_1);
        assertEq(oFlowBalanceBefore - oFlowBalanceAfter, TOKEN_1);
        assertEq(daiBalanceBefore - daiBalanceAfter, discountedPrice);
        assertEq(
            treasuryDaiBalanceAfter - treasuryDaiBalanceBefore,
            discountedPrice
        );
    }

    function testCannotExercisePastDeadline() public {
        vm.startPrank(address(owner));
        FLOW.approve(address(oFlow), TOKEN_1);
        oFlow.mint(address(owner), TOKEN_1);

        DAI.approve(address(oFlow), TOKEN_100K);
        vm.expectRevert(OptionToken_PastDeadline.selector);
        oFlow.exercise(TOKEN_1, TOKEN_1, address(owner), block.timestamp - 1);
        vm.stopPrank();
    }

    function testCannotExerciseWithSlippageTooHigh() public {
        vm.startPrank(address(owner));
        FLOW.approve(address(oFlow), TOKEN_1);
        oFlow.mint(address(owner), TOKEN_1);

        washTrades();
        uint256 discountedPrice = oFlow.getDiscountedPrice(TOKEN_1);

        DAI.approve(address(oFlow), TOKEN_100K);
        vm.expectRevert(OptionToken_SlippageTooHigh.selector);
        oFlow.exercise(TOKEN_1, discountedPrice - 1, address(owner));
        vm.stopPrank();
    }
}
