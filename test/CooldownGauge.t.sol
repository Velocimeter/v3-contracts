pragma solidity 0.8.13;

import "./BaseTest.sol";
import "contracts/factories/CooldownGaugeFactory.sol";
import "contracts/CooldownGauge.sol";
//TODO test

//Normal widraw deposit
// widrawe with skip
// stake rewards callucation
// check if user is not earning the rewards after the widraw

contract CooldownGaugeTest is BaseTest {
    VotingEscrow escrow;
    CooldownGaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    CooldownGauge gauge;

    function setUp() public {
        deployOwners();
        deployCoins();
        mintStables();

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2 * TOKEN_1M; // use 1/2 for veNFT position
        amounts[1] = TOKEN_1M;
        mintFlow(owners, amounts);

        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(FLOW), address(artProxy), owners[0]);

        deployPairFactoryAndRouter();

        gaugeFactory = new CooldownGaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(escrow), address(factory), address(gaugeFactory), address(bribeFactory));
        factory.setVoter(address(voter));

        address[] memory tokens = new address[](4);
        tokens[0] = address(USDC);
        tokens[1] = address(FRAX);
        tokens[2] = address(DAI);
        tokens[3] = address(FLOW);
        voter.initialize(tokens, address(owner));
        escrow.setVoter(address(voter));

        deployOptionTokenV2WithOwner(
            address(owner),
            address(gaugeFactory),
            address(voter),
            address(escrow)
        );

        gaugeFactory.setOFlow(address(oFlowV2));

        deployPairWithOwner(address(owner));
        
        address address1 = factory.getPair(address(FLOW), address(DAI), false);

        pair = Pair(address1);
        address gaugeAddress = voter.createGauge(address(pair), 0);
        gauge = CooldownGauge(gaugeAddress);
        
        oFlowV2.setGauge(address(gauge));
        
    }

    
    function testGaugeLock() public {
        vm.startPrank(address(owner));
        washTrades();
        flowDaiPair.approve(address(gauge),1000);

        uint256 lpBalanceBefore = flowDaiPair.balanceOf(address(owner));
        gauge.depositWithLock(address(owner), 1, 7 * 86400);
        vm.warp(block.timestamp + 7 * 86400 + 1);
        gauge.withdraw(1);
        vm.warp(block.timestamp + 3 * 86400 + 1);
        gauge.withdrawFromCooldown();
        uint256 lpBalanceAfter = flowDaiPair.balanceOf(address(owner));
        vm.stopPrank();

        assertEq(gauge.balanceWithLock(address(owner)),0);
        assertEq(lpBalanceBefore - lpBalanceAfter, 0);
    }

    function testGaugeWithdrawWithLock() public {
        vm.startPrank(address(owner));
        washTrades();
        flowDaiPair.approve(address(gauge),1000);

        uint256 lpBalanceBefore = flowDaiPair.balanceOf(address(owner));
        gauge.depositWithLock(address(owner), 1, 7 * 86400);
        vm.expectRevert("The lock didn't expire");
        gauge.withdraw(1);
        uint256 lpBalanceAfter = flowDaiPair.balanceOf(address(owner));
        vm.stopPrank();

        assertEq(gauge.balanceWithLock(address(owner)),1);
        assertEq(lpBalanceBefore - lpBalanceAfter, 1);
    }

    function testGaugeLockAfterExpire() public {
        vm.startPrank(address(owner));
        washTrades();
        flowDaiPair.approve(address(gauge),1000);

        uint256 lpBalanceBefore = flowDaiPair.balanceOf(address(owner));
        gauge.depositWithLock(address(owner), 1, 7 * 86400);
        vm.warp(block.timestamp + 7 * 86400 + 1);
        gauge.depositWithLock(address(owner), 2, 7 * 86400);
        uint256 expectedLockEnd = block.timestamp +  7 * 86400;
        gauge.withdraw(1);
        vm.warp(block.timestamp + 3 * 86400 + 1);
        gauge.withdrawFromCooldown();
        uint256 lpBalanceAfter = flowDaiPair.balanceOf(address(owner));
        vm.stopPrank();

        assertEq(gauge.lockEnd(address(owner)),expectedLockEnd);
        assertEq(gauge.balanceWithLock(address(owner)),2);
        assertEq(lpBalanceBefore - lpBalanceAfter, 2);
    }

    function testGaugeLockExtendLock() public {
        vm.startPrank(address(owner));
        washTrades();
        flowDaiPair.approve(address(gauge),1000);

        uint256 lpBalanceBefore = flowDaiPair.balanceOf(address(owner));
        gauge.depositWithLock(address(owner), 1, 14 * 86400);
        vm.warp(block.timestamp + 7 * 86400 + 1);
        gauge.depositWithLock(address(owner), 2, 8 * 86400);
        uint256 lpBalanceAfter = flowDaiPair.balanceOf(address(owner));
        vm.stopPrank();

        assertEq(gauge.lockEnd(address(owner)),block.timestamp +  8 * 86400);
        assertEq(gauge.balanceWithLock(address(owner)),3);
        assertEq(lpBalanceBefore - lpBalanceAfter, 3);
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
 
}