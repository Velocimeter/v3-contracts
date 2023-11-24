pragma solidity 0.8.13;

import './BaseTest.sol';
import "contracts/factories/GaugeFactoryV3.sol";
import "contracts/LockDrop.sol";

contract LockDropTests is BaseTest {
    VotingEscrow escrow;
    GaugeFactoryV3 gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    GaugeV3 gauge;
    LockDrop lockDropContract;

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

        gaugeFactory = new GaugeFactoryV3();
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
        gauge = GaugeV3(gaugeAddress);
        
        oFlowV2.setGauge(address(gauge));
        
        lockDropContract = new LockDrop(address(gauge),5);

        gaugeFactory.addOTokenFor(address(gauge), address(lockDropContract));
    }
    
    function testDeposit() public {
        vm.startPrank(address(owner));
        washTrades(address(owner));
        flowDaiPair.approve(address(lockDropContract), TOKEN_1 * 2);
        lockDropContract.depositWithLock(TOKEN_1);
        lockDropContract.depositWithLock(TOKEN_1);

        assertEq(gauge.balanceWithLock(address(owner)),TOKEN_1*2);
        assertEq(gauge.lockEnd(address(owner)),block.timestamp + 5);

        vm.stopPrank();
    }

    function testClaim() public {
        vm.startPrank(address(owner));
        washTrades(address(owner));
        flowDaiPair.approve(address(lockDropContract), TOKEN_1 );
        lockDropContract.depositWithLock(TOKEN_1);
        vm.stopPrank();

        FLOW.approve(address(lockDropContract), TOKEN_1 * 2);
        lockDropContract.rewardsDeposit(address(FLOW),TOKEN_1);

        vm.startPrank(address(owner));
        uint256 flowBalanceBefore = FLOW.balanceOf(address(owner));
        lockDropContract.claim();
        uint256 flowBalanceAfter = FLOW.balanceOf(address(owner));
        vm.stopPrank();

        assertEq(flowBalanceAfter - flowBalanceBefore,TOKEN_1);
    }

    function testClaimTwoUsers() public {
        vm.startPrank(address(owner));
        washTrades(address(owner));
        flowDaiPair.approve(address(lockDropContract), TOKEN_1 );
        lockDropContract.depositWithLock(TOKEN_1);
        vm.stopPrank();

        vm.startPrank(address(owner2));
        washTrades(address(owner2));
        flowDaiPair.approve(address(lockDropContract), TOKEN_1*3);
        lockDropContract.depositWithLock(TOKEN_1*3);
        vm.stopPrank();

        FLOW.approve(address(lockDropContract), TOKEN_1 * 2);
        lockDropContract.rewardsDeposit(address(FLOW),TOKEN_1);

        vm.startPrank(address(owner));
        uint256 flowBalanceBefore = FLOW.balanceOf(address(owner));
        lockDropContract.claim();
        uint256 flowBalanceAfter = FLOW.balanceOf(address(owner));
        assertEq(flowBalanceAfter - flowBalanceBefore,TOKEN_1*1/4);

        vm.startPrank(address(owner2));
        flowBalanceBefore = FLOW.balanceOf(address(owner2));
        lockDropContract.claim();
        flowBalanceAfter = FLOW.balanceOf(address(owner2));
        assertEq(flowBalanceAfter - flowBalanceBefore,TOKEN_1*3/4);
        vm.stopPrank();
    } 

    function washTrades(address _owner) public {
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
            address(_owner),
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
                address(_owner),
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
                address(_owner),
                block.timestamp
            );
        }
    }
}