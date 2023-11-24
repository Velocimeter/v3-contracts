// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import 'contracts/interfaces/IERC20.sol';
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {IGaugeV2} from "./interfaces/IGaugeV2.sol";


contract LockDrop is Ownable,ReentrancyGuard {
    address public immutable gauge;
    address public immutable lpToken;
    address public rewardsToken;

    uint256 public lockDuration;

    bool public seeded;
    uint256 public totalAirdrop;
    
    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    event RewardsDeposit(uint256 amount);
    event DepositWithLock(address indexed from, uint amount,uint lockTime);
    event Claimed(address _who, uint amount);


    constructor(address _gauge,uint _lockDuration) {
        gauge = _gauge;
        lockDuration = _lockDuration;
        lpToken = IGaugeV2(gauge).stake();
    }

    function depositWithLock(uint256 amount) nonReentrant external {
      require(!seeded, "LockDrop is completed");

      _safeTransferFrom(lpToken, msg.sender, address(this), amount);

      balanceOf[msg.sender] += amount;
      totalSupply += amount;

      _safeApprove(lpToken, gauge, amount);
      IGaugeV2(gauge).depositWithLock(msg.sender, amount, lockDuration);

      emit DepositWithLock(msg.sender,amount,lockDuration);
    }

    function claim() external nonReentrant {
        require(seeded, "LockDrop is not completed");
        require(balanceOf[msg.sender] > 0, "No LockDrop");

        uint airdropAmount = (balanceOf[msg.sender] * totalAirdrop) / totalSupply;

        balanceOf[msg.sender] = 0;

        _safeTransfer(rewardsToken,msg.sender,airdropAmount);

        emit Claimed(msg.sender,airdropAmount);
    }

    function rewardsDeposit(address _rewardsToken,uint256 amount) onlyOwner external {
        require(!seeded, "LockDrop is completed");

        rewardsToken = _rewardsToken;

        _safeTransferFrom(rewardsToken,msg.sender, address(this), amount);

        totalAirdrop += amount;
        seeded = true;

        emit RewardsDeposit(amount);
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeApprove(address token, address spender, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}