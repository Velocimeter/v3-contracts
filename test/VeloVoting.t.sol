// 1:1 with Hardhat test
pragma solidity 0.8.13;

import "./BaseTest.sol";

contract VeloVotingTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    RewardsDistributor distributor;
    Minter minter;
    TestOwner team;

    function setUp() public {
        vm.warp(block.timestamp + 1 weeks); // put some initial time in

        deployOwners();
        deployCoins();
        mintStables();
        uint256[] memory amountsVelo = new uint256[](2);
        amountsVelo[0] = 1e25;
        amountsVelo[1] = 1e25;
        mintFlow(owners, amountsVelo);
        team = new TestOwner();
        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(FLOW), address(artProxy), owners[0]);
        deployPairFactoryAndRouter();
        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory(csrNftId);
        voter = new Voter(
            address(escrow),
            address(factory),
            address(gaugeFactory),
            address(bribeFactory),
            csrNftId
        );

        factory.setVoter(address(voter));
        deployPairWithOwner(address(owner));
        deployOptionTokenWithOwner(address(owner), address(gaugeFactory));
        gaugeFactory.setOFlow(address(oFlow));

        address[] memory tokens = new address[](2);
        tokens[0] = address(FRAX);
        tokens[1] = address(FLOW);
        voter.initialize(tokens, address(owner));
        FLOW.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, FIFTY_TWO_WEEKS);
        distributor = new RewardsDistributor(address(escrow), csrNftId);
        escrow.setVoter(address(voter));

        minter = new Minter(
            address(voter),
            address(escrow),
            address(distributor),
            csrNftId
        );
        distributor.setDepositor(address(minter));
        FLOW.setMinter(address(minter));

        FLOW.approve(address(router), TOKEN_1);
        FRAX.approve(address(router), TOKEN_1);
        router.addLiquidity(
            address(FRAX),
            address(FLOW),
            false,
            TOKEN_1,
            TOKEN_1,
            0,
            0,
            address(owner),
            block.timestamp
        );

        address pair = router.pairFor(address(FRAX), address(FLOW), false);

        FLOW.approve(address(voter), 5 * TOKEN_100K);
        voter.createGauge(pair, 0);
        vm.roll(block.number + 1); // fwd 1 block because escrow.balanceOfNFT() returns 0 in same block
        assertGt(escrow.balanceOfNFT(1), 995063075414519385);
        assertEq(FLOW.balanceOf(address(escrow)), TOKEN_1);

        address[] memory pools = new address[](1);
        pools[0] = pair;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        voter.vote(1, pools, weights);

        Minter.Claim[] memory claims = new Minter.Claim[](1);
        claims[0] = Minter.Claim({
            claimant: address(owner),
            amount: TOKEN_100K,
            lockTime: FIFTY_TWO_WEEKS
        });
        minter.initialMintAndLock(claims, 3 * TOKEN_100K);
        minter.startActivePeriod();

        assertEq(escrow.ownerOf(2), address(owner));
        assertEq(escrow.ownerOf(3), address(0));
        vm.roll(block.number + 1);
        assertEq(FLOW.balanceOf(address(minter)), 2 * TOKEN_100K);

        uint256 before = FLOW.balanceOf(address(owner));
        minter.update_period(); // initial period week 1
        uint256 after_ = FLOW.balanceOf(address(owner));
        assertEq(minter.weekly(), 3 * TOKEN_100K);
        assertEq(after_ - before, 0);
        vm.warp(block.timestamp + ONE_WEEK);
        vm.roll(block.number + 1);
        before = FLOW.balanceOf(address(owner));
        minter.update_period(); // initial period week 2
        after_ = FLOW.balanceOf(address(owner));
        assertLt(minter.weekly(), 3 * TOKEN_100K); // <13m for week shift
    }

    // Note: _vote and _reset are not included in one-vote-per-epoch
    // Only vote() and poke() should be constrained as they must be called by the owner
    // reset() can be called by anyone before voting to abstain votes before transferring to a new wallet

    function testCannotChangeVoteAndPokeAndResetInSameEpoch() public {
        address pair = router.pairFor(address(FRAX), address(FLOW), false);

        // vote
        vm.warp(block.timestamp + 1 weeks);
        address[] memory pools = new address[](1);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        voter.vote(1, pools, weights);

        // fwd half epoch
        vm.warp(block.timestamp + 1 weeks / 2);

        // try voting again and fail
        pools[0] = address(pair2);
        vm.expectRevert(abi.encodePacked("TOKEN_ALREADY_VOTED_THIS_EPOCH"));
        voter.vote(1, pools, weights);

        // try poking and fail
        vm.expectRevert(abi.encodePacked("TOKEN_ALREADY_VOTED_THIS_EPOCH"));
        voter.poke(1);

        // try resetting and fail
        assertGt(voter.usedWeights(1), 0);
        assertGt(voter.votes(1, address(pair)), 0);
        vm.expectRevert(abi.encodePacked("TOKEN_ALREADY_VOTED_THIS_EPOCH"));
        voter.reset(1);
        assertGt(voter.usedWeights(1), 0);
        assertGt(voter.votes(1, address(pair)), 0);
    }

    function testCanChangeVoteOrResetInNextEpoch() public {
        address pair = router.pairFor(address(FRAX), address(FLOW), false);

        // vote
        vm.warp(block.timestamp + 1 weeks);
        address[] memory pools = new address[](1);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        voter.vote(1, pools, weights);

        // fwd whole epoch
        vm.warp(block.timestamp + 1 weeks);

        // try voting again and fail
        pools[0] = address(pair2);
        voter.vote(1, pools, weights);

        // fwd whole epoch
        vm.warp(block.timestamp + 1 weeks);

        voter.reset(1);
    }

    function testCanResetAndTransferAndVoteInNextEpoch() public {
        address pair = router.pairFor(address(FRAX), address(FLOW), false);

        // vote
        vm.warp(block.timestamp + 1 weeks);
        address[] memory pools = new address[](1);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        voter.vote(1, pools, weights);

        // fwd whole epoch
        vm.warp(block.timestamp + 1 weeks);

        voter.reset(1);
        escrow.safeTransferFrom(address(this), address(owner2), 1);
        pools[0] = address(pair2);

        vm.startPrank(address(owner2));
        voter.vote(1, pools, weights);
        vm.stopPrank();
    }
}
