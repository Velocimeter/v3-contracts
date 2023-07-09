pragma solidity 0.8.13;

import "contracts/interfaces/IVotingEscrow.sol";
import "contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @dev This contract allow users to convert one token to another.
 * It requires both tokens to have valid contract addresses.
 * It requires that it is filled up first with liquid v2 tokens., they dont need to be exact.
 * Any tokens that get sent here accidently can be sent back out, except v1 token.
 */
contract FlowConvertor is Ownable {
    address public immutable v1;
    address public immutable v2;
    address public immutable votingEscrowV1;
    address public immutable votingEscrowV2;

    constructor(
        address _v1,
        address _v2,
        address _votingEscrowV1,
        address _votingEscrowV2
    ) {
        v1 = _v1;
        v2 = _v2;
        votingEscrowV1 = _votingEscrowV1;
        votingEscrowV2 = _votingEscrowV2;
    }

    /**
     * @dev Transfers ERC20 v1 from user to contract, and Transfer ERC20 v2 to user, 1 to 1.
     */
    function redeem(uint256 amount) public {
        require(amount > 0, "you dont have and v1 tokens");
        _safeTransferFrom(v1, _msgSender(), address(this), amount);
        _safeTransfer(v2, _msgSender(), amount);
    }

    /**
     * @dev Transfers ERC20 v1 from user to contract, and Transfer ERC20 v2 to an address specified, 1 to 1.
     */
    function redeemTo(address _to, uint256 amount) public {
        require(amount > 0, "you dont have and v1 tokens");
        _safeTransferFrom(v1, _msgSender(), address(this), amount);
        _safeTransfer(v2, _to, amount);
    }

    /**
     * @dev Transfers V1 NFT from user to contract, and create NFT v2 to user, 1 to 1.
     */
    function redeemNft(uint256 tokenId) public returns (uint256 newTokenId) {
        IVotingEscrow.LockedBalance memory locked = IVotingEscrow(
            votingEscrowV1
        ).locked(tokenId);
        IVotingEscrow(votingEscrowV1).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        uint256 amount = uint256(int256(locked.amount));
        _safeApprove(v2, votingEscrowV2, amount);
        newTokenId = IVotingEscrow(votingEscrowV2).create_lock_for(
            amount,
            locked.end - block.timestamp,
            msg.sender
        );
    }

    /**
     * @dev Transfers V1 NFT from user to contract, and create NFT v2 to an address specified, 1 to 1.
     */
    function redeemNftTo(
        address _to,
        uint256 tokenId
    ) public returns (uint256 newTokenId) {
        IVotingEscrow.LockedBalance memory locked = IVotingEscrow(
            votingEscrowV1
        ).locked(tokenId);
        IVotingEscrow(votingEscrowV1).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        uint256 amount = uint256(int256(locked.amount));
        _safeApprove(v2, votingEscrowV2, amount);
        newTokenId = IVotingEscrow(votingEscrowV2).create_lock_for(
            amount,
            locked.end - block.timestamp,
            _to
        );
    }

    /**
     * @dev Allows owner to clean out the contract of ANY tokens including v2, but not v1
     */
    function inCaseTokensGetStuck(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        require(_token != address(v1), "these tkns are essentially burnt");
        _safeTransfer(_token, _to, _amount);
    }

    /**
     * @dev Allows owner sweep out all the remaining v2 tokens.
     */
    function sweepV2(address _to) public onlyOwner {
        uint256 _surplus = IERC20(v2).balanceOf(address(this));
        _safeTransfer(v2, _to, _surplus);
    }

    /**
     * @dev Allows owner sweep out all the v1 tokens to recover the FLOW.
     */
    function sweepV1(address _to) public onlyOwner {
        uint256 _cache = IERC20(v1).balanceOf(address(this));
        _safeTransfer(v1, _to, _cache);
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}