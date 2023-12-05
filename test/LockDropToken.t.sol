// 1:1 with Hardhat test
pragma solidity 0.8.13;

import "./BaseTest.sol";
import "contracts/GaugeV3.sol";
import "contracts/LockDropToken.sol";
import "contracts/factories/GaugeFactoryV3.sol";

contract LockDropTokenTest is BaseTest {
    GaugeFactoryV3 gaugeFactory;
    VotingEscrow escrow;
    Voter voter;
    BribeFactory bribeFactory;
    GaugeV3 gauge;
    LockDropToken lockDrop;

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
    event ExerciseLp(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 paymentAmount,
        uint256 lpAmount
    );
    event SetPairAndPaymentToken(
        IPair indexed newPair,
        address indexed newPaymentToken
    );
    event SetTreasury(address indexed newTreasury,address indexed newVMTreasury);
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

        gaugeFactory = new GaugeFactoryV3();
        bribeFactory = new BribeFactory();
        VeArtProxy artProxy = new VeArtProxy();
        
        escrow = new VotingEscrow(address(FLOW), address(artProxy), owners[0]);
        
        deployPairFactoryAndRouter();
        voter = new Voter(address(escrow), address(factory), address(gaugeFactory), address(bribeFactory));
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
       
        deployLockDropTokenWithOwner(
            address(owner),
            address(gaugeFactory),
            address(voter),
            address(escrow)
        );
        gaugeFactory.setOFlow(address(oFlowV3));

        gauge = GaugeV3(voter.createGauge(address(flowDaiPair), 0));
        oFlowV3.updateGauge();
        lockDrop.updateGauge();

        gaugeFactory.addOTokenFor(address(gauge), address(lockDrop));
    }

    function deployLockDropTokenWithOwner(
        address _owner,
        address _gaugeFactory,
        address _voter,
        address _escrow
    ) public {
        lockDrop = new LockDropToken(
            "LockDropToken",
            "ldFLOW",
            _owner,
            address(DAI),
            address(FLOW),
            flowDaiPair,
            _gaugeFactory,
            _voter,
            _escrow,
            address(router)
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
        lockDrop.setPairAndPaymentToken(IPair(flowFraxPair), address(FRAX));
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
        lockDrop.setPairAndPaymentToken(IPair(flowFraxPair), address(FRAX));
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
        lockDrop.setPairAndPaymentToken(IPair(daiFraxPair), address(DAI));
        vm.stopPrank();
    }

    function testMint() public {
        uint256 flowBalanceBefore = FLOW.balanceOf(address(owner));
        uint256 oFlowV3BalanceBefore = lockDrop.balanceOf(address(owner));

        vm.startPrank(address(owner));
        FLOW.approve(address(lockDrop), TOKEN_1);
        lockDrop.mint(address(owner), TOKEN_1);
        vm.stopPrank();

        uint256 flowBalanceAfter = FLOW.balanceOf(address(owner));
        uint256 oFlowV3BalanceAfter = lockDrop.balanceOf(address(owner));

        assertEq(flowBalanceBefore - flowBalanceAfter, TOKEN_1);
        assertEq(oFlowV3BalanceAfter - oFlowV3BalanceBefore, TOKEN_1);
    }

    function testNonMinterCannotMint() public {
        vm.startPrank(address(owner2));
        FLOW.approve(address(oFlowV3), TOKEN_1);
        vm.expectRevert(OptionToken_NoMinterRole.selector);
        lockDrop.mint(address(owner2), TOKEN_1);
        vm.stopPrank();
    }


   

    function testNonPauserCannotPause() public {
        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoPauserRole.selector);
        lockDrop.pause();
        vm.stopPrank();
    }

    function testNonAdminCannotUnpause() public {
        vm.startPrank(address(owner));
        lockDrop.pause();
        vm.stopPrank();

        vm.startPrank(address(owner2));
        vm.expectRevert(OptionToken_NoAdminRole.selector);
        lockDrop.unPause();
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


    function testExerciseVe() public { 
        vm.startPrank(address(owner));
        FLOW.approve(address(lockDrop), TOKEN_1);
        // mint Option token to owner 2
        lockDrop.mint(address(owner2), TOKEN_1);

        washTrades();
        vm.stopPrank();

        uint256 nftBalanceBefore = escrow.balanceOf(address(owner2));
        uint256 oFlowV3BalanceBefore = lockDrop.balanceOf(address(owner2));
        uint256 daiBalanceBefore = DAI.balanceOf(address(owner2));
        uint256 treasuryDaiBalanceBefore = DAI.balanceOf(address(owner));
        uint256 rewardGaugeDaiBalanceBefore = DAI.balanceOf(address(gauge));

        vm.startPrank(address(owner2));
        DAI.approve(address(lockDrop), TOKEN_100K);
        vm.expectEmit(true, true, false, true);
        emit ExerciseVe(
            address(owner2),
            address(owner2),
            TOKEN_1,
            0,
            escrow.currentTokenId() + 1
        );
        (, uint256 nftId) = lockDrop.exerciseVe(
            TOKEN_1,
            address(owner2),
            block.timestamp
        );
        vm.stopPrank();

        uint256 nftBalanceAfter = escrow.balanceOf(address(owner2));
        uint256 oFlowV3BalanceAfter = lockDrop.balanceOf(address(owner2));
        uint256 daiBalanceAfter = DAI.balanceOf(address(owner2));
        uint256 treasuryDaiBalanceAfter = DAI.balanceOf(address(owner));
        uint256 rewardGaugeDaiAfter = DAI.balanceOf(address(gauge));

        assertEq(nftBalanceAfter - nftBalanceBefore, 1);
        assertEq(oFlowV3BalanceBefore - oFlowV3BalanceAfter, TOKEN_1);
        assertEq(daiBalanceBefore - daiBalanceAfter, 0);
        assertEq(treasuryDaiBalanceAfter - treasuryDaiBalanceBefore,0);
        assertEq(
             (rewardGaugeDaiAfter - rewardGaugeDaiBalanceBefore),
             0
        );
        assertGt(escrow.balanceOfNFT(nftId), 0);
    }

    function testExerciseLp() public { 
        vm.startPrank(address(owner)); 
        FLOW.approve(address(lockDrop), TOKEN_1);
        // mint Option token to owner 2
        lockDrop.mint(address(owner2), TOKEN_1);

        washTrades();
        vm.stopPrank();
        uint256 flowBalanceBefore = FLOW.balanceOf(address(owner2));
        uint256 oFlowV3BalanceBefore = lockDrop.balanceOf(address(owner2));
        uint256 daiBalanceBefore = DAI.balanceOf(address(owner2));
        uint256 treasuryDaiBalanceBefore = DAI.balanceOf(address(owner));
        uint256 rewardGaugeDaiBalanceBefore = DAI.balanceOf(address(gauge));

        (uint256 underlyingReserve, uint256 paymentReserve) = IRouter(router).getReserves(address(FLOW), address(DAI), false);
        uint256 paymentAmountToAddLiquidity = (TOKEN_1 * paymentReserve) /  underlyingReserve;
      
        vm.startPrank(address(owner2));
        DAI.approve(address(lockDrop), TOKEN_100K);
        vm.expectEmit(true, true, false, true); 
        emit ExerciseLp(
            address(owner2),
            address(owner2),
            TOKEN_1,
            0,
            1000000000999700046
        );

  
        lockDrop.exerciseLp(TOKEN_1, address(owner2),block.timestamp);
        vm.stopPrank();

        uint256 flowBalanceAfter = FLOW.balanceOf(address(owner2));
        uint256 oFlowV3BalanceAfter = oFlowV3.balanceOf(address(owner2));
        uint256 daiBalanceAfter = DAI.balanceOf(address(owner2));
        uint256 treasuryDaiBalanceAfter = DAI.balanceOf(address(owner));
        uint256 rewardGaugeDaiAfter = DAI.balanceOf(address(gauge));

        assertEq(gauge.lockEnd(address(owner2)),block.timestamp + 12 * 7 * 86400);

        assertEq(flowBalanceAfter - flowBalanceBefore, 0);
        assertEq(oFlowV3BalanceBefore - oFlowV3BalanceAfter, TOKEN_1);
        assertEq(daiBalanceBefore - daiBalanceAfter, paymentAmountToAddLiquidity);
        assertEq(treasuryDaiBalanceAfter - treasuryDaiBalanceBefore,0);
        assertEq(
             rewardGaugeDaiAfter - rewardGaugeDaiBalanceBefore,
             0
        );
    }
}
