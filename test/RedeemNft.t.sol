// 1:1 with Hardhat test
pragma solidity 0.8.13;

import "./BaseTest.sol";
import "contracts/FlowConvertor.sol";
import "contracts/VotingEscrowV2.sol";

contract RedeemNftTest is BaseTest {
    Flow FLOW_V2;
    VotingEscrow escrow;
    VotingEscrowV2 escrow_V2;
    FlowConvertor flowConvertor;
    int128 public constant NEW_MAX_LOCK_TIME = 26 * 7 * 86400;

    function setUp() public {
        deployOwners();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e21;
        FLOW = new Flow(msg.sender, 6_000_000e18, msg.sender);
        mintFlow(owners, amounts);

        FLOW_V2 = new Flow(msg.sender, 6_000_000e18, msg.sender);
        for (uint256 i = 0; i < amounts.length; i++) {
            FLOW_V2.mint(owners[i], amounts[i]);
        }

        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(FLOW), address(artProxy), owners[0]);
        escrow_V2 = new VotingEscrowV2(
            address(FLOW_V2),
            address(artProxy),
            address(owner),
            NEW_MAX_LOCK_TIME,
            csrNftId
        );
        flowConvertor = new FlowConvertor(
            address(FLOW),
            address(FLOW_V2),
            address(escrow),
            address(escrow_V2)
        );
        FLOW_V2.transfer(address(flowConvertor), amounts[0] / 2);
    }

    function testRedeemNft() public {
        FLOW.approve(address(escrow), 1e19);
        uint256 lockDuration = 7 * 24 * 3600; // 1 week

        // Balance should be zero before and 1 after creating the lock
        assertEq(escrow.balanceOf(address(owner)), 0);
        uint256 tokenId = escrow.create_lock(1e19, lockDuration);
        assertEq(escrow.currentTokenId(), 1);
        assertEq(escrow.ownerOf(1), address(owner));
        assertEq(escrow.balanceOf(address(owner)), 1);

        escrow.approve(address(flowConvertor), tokenId);
        assertEq(escrow.balanceOf(address(flowConvertor)), 0);
        assertEq(escrow_V2.balanceOf(address(owner)), 0);
        uint256 newTokenId = flowConvertor.redeemNft(tokenId);
        assertEq(escrow.ownerOf(1), address(flowConvertor));
        assertEq(escrow.balanceOf(address(flowConvertor)), 1);
        assertEq(escrow_V2.currentTokenId(), 1);
        assertEq(escrow_V2.ownerOf(1), address(owner));
        assertEq(escrow_V2.balanceOf(address(owner)), 1);

        // Test locked balance and duration
        (int256 amount, uint256 end) = escrow_V2.locked(newTokenId);
        assertEq(amount, 1e19 / 1000);
        assertEq(end, lockDuration);
    }

    function testRedeemNftTo() public {
        FLOW.approve(address(escrow), 1e19);
        uint256 lockDuration = 7 * 24 * 3600; // 1 week

        // Balance should be zero before and 1 after creating the lock
        assertEq(escrow.balanceOf(address(owner)), 0);
        uint256 tokenId = escrow.create_lock(1e19, lockDuration);
        assertEq(escrow.currentTokenId(), 1);
        assertEq(escrow.ownerOf(1), address(owner));
        assertEq(escrow.balanceOf(address(owner)), 1);

        escrow.approve(address(flowConvertor), tokenId);
        assertEq(escrow.balanceOf(address(flowConvertor)), 0);
        assertEq(escrow_V2.balanceOf(address(owner)), 0);
        uint256 newTokenId = flowConvertor.redeemNftTo(
            address(owner2),
            tokenId
        );
        assertEq(escrow.ownerOf(1), address(flowConvertor));
        assertEq(escrow.balanceOf(address(flowConvertor)), 1);
        assertEq(escrow_V2.currentTokenId(), 1);
        assertEq(escrow_V2.ownerOf(1), address(owner2));
        assertEq(escrow_V2.balanceOf(address(owner2)), 1);

        // Test locked balance and duration
        (int256 amount, uint256 end) = escrow_V2.locked(newTokenId);
        assertEq(amount, 1e19 / 1000);
        assertEq(end, lockDuration);
    }

    function testRedeemNftWithMoreThanOneWeekLock() public {
        FLOW.approve(address(escrow), 1e19);
        uint256 lockDuration = 14 * 24 * 3600; // 1 week

        // Balance should be zero before and 1 after creating the lock
        assertEq(escrow.balanceOf(address(owner)), 0);
        uint256 tokenId = escrow.create_lock(1e19, lockDuration);
        assertEq(escrow.currentTokenId(), 1);
        assertEq(escrow.ownerOf(1), address(owner));
        assertEq(escrow.balanceOf(address(owner)), 1);

        escrow.approve(address(flowConvertor), tokenId);
        assertEq(escrow.balanceOf(address(flowConvertor)), 0);
        assertEq(escrow_V2.balanceOf(address(owner)), 0);
        uint256 newTokenId = flowConvertor.redeemNft(tokenId);
        assertEq(escrow.ownerOf(1), address(flowConvertor));
        assertEq(escrow.balanceOf(address(flowConvertor)), 1);
        assertEq(escrow_V2.currentTokenId(), 1);
        assertEq(escrow_V2.ownerOf(1), address(owner));
        assertEq(escrow_V2.balanceOf(address(owner)), 1);

        // Test locked balance and duration
        (int256 amount, uint256 end) = escrow_V2.locked(newTokenId);
        assertEq(amount, 1e19 / 1000);
        assertEq(end, lockDuration / 2);
    }

    function testRedeemNftWithMoreThanOneWeekLockTo() public {
        FLOW.approve(address(escrow), 1e19);
        uint256 lockDuration = 14 * 24 * 3600; // 1 week

        // Balance should be zero before and 1 after creating the lock
        assertEq(escrow.balanceOf(address(owner)), 0);
        uint256 tokenId = escrow.create_lock(1e19, lockDuration);
        assertEq(escrow.currentTokenId(), 1);
        assertEq(escrow.ownerOf(1), address(owner));
        assertEq(escrow.balanceOf(address(owner)), 1);

        escrow.approve(address(flowConvertor), tokenId);
        assertEq(escrow.balanceOf(address(flowConvertor)), 0);
        assertEq(escrow_V2.balanceOf(address(owner)), 0);
        uint256 newTokenId = flowConvertor.redeemNftTo(
            address(owner2),
            tokenId
        );
        assertEq(escrow.ownerOf(1), address(flowConvertor));
        assertEq(escrow.balanceOf(address(flowConvertor)), 1);
        assertEq(escrow_V2.currentTokenId(), 1);
        assertEq(escrow_V2.ownerOf(1), address(owner2));
        assertEq(escrow_V2.balanceOf(address(owner2)), 1);

        // Test locked balance and duration
        (int256 amount, uint256 end) = escrow_V2.locked(newTokenId);
        assertEq(amount, 1e19 / 1000);
        assertEq(end, lockDuration / 2);
    }

    // TODO: test redeem after few months
}
