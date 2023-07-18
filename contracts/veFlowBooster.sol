// SPDX-License-Identifier: MIT

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "contracts/interfaces/ITurnstile.sol";
import "contracts/interfaces/IERC20.sol";
import "contracts/interfaces/IVotingEscrow.sol";
import "contrancts/interfaces/IPair.sol";

pragma solidity ^0.8.13;

contract veFlowBooster is Ownable {
    address public constant TURNSTILE = 0xEcf044C5B4b867CFda001101c617eCd347095B44;
    address public paymentToken;
    address public pair;
    address public router;
    address public constant flow;
    address public constant voting_escrow;
    uint256 public matchRate = 50; // 50%
    uint256 public constant maxLock;

    event Boosted(uint256 indexed _timestamp, uint256 _totalLocked, address _locker);
    event Donated(uint256 indexed _timestamp, uint256 _amount);
    event MatchRateChanged(uint256 indexed _timestamp, uint256 _newRate);

    constructor(address _voting_escrow, address _team, address _paymentToken, address _pair, uint256 _maxLock, address _router, uint256 _csrNftId) {
        voting_escrow = _voting_escrow;
        _transferOwnership(_team);
        ITurnstile(TURNSTILE).assign(_csrNftId);
        flow = IVotingEscrow(voting_escrow).token();
        paymentToken = _paymentToken;
        pair = _pair;
        maxLock = _maxLock;
        router = _router;
        _giveAllowances();
    }

    function balanceOfFlow() pubic view returns (uint){
        return IERC20(flow).balanceOf(address(this));
    }

    function maxLockableAmount() public view returns (uint){
         uint256 flowBal = balanceOfFlow();
         uint256 amnt = flowBal * matchRate / 100;
         return amnt;
    }

    function setMatchRate(uint256 _rate) external onlyOwner {
        require(_rate <= 100, 'cant give more than 1-1');
        matchrate = _rate;  

        emit MatchRateChanged(matchRate);      
    }
    function setPaymentToken(address _paymentToken) external onlyOwner {
        require(_paymentToken != address(0));
        paymentToken = _paymentToken;
    }
    function setPair(address _pair) external onlyOwner {
        require(_pair != address(0));
        pair = _pair;
    }
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0));
        router = _router;
    }

    function boostedBuyAndVeLock(uint256 _amount, uint _minOut, uint _deadline) public {
        require(_amount > 0, 'need to lock at least 1 paymentToken');
        require(balanceOfFlow > 0, 'no extra FLOW for boosting');
        IERC20(paymentToken).transferFrom(msg.sender, address(this), _amount);

        if (_minOut == 0) {
            _minOut = 1;
        }

        uint256 flowBefore = balanceOfFlow();
        IRouter(router).swapExactTokensForTokensSimple(_amount, _minOut, paymentToken, flow, false, address(this), _deadline);
        uint256 flowAfter = balanceOfFlow();
        uint256 flowResult = flowAfter - flowBefore;

        uint256 amountToLock = _flowResult * matchRate  / 100 + _amount;
        IVotingEscrow(voting_escrow).create_lock_for(amountToLock, maxLock, msg.sender);

        emit Boosted(amountToLock, msg.sender);
    }

    function donateFlow(uint256 _amount) public {
        require(_amount > 0, 'need to add at least 1 FLOW');
        IERC20(flow).transferFrom(msg.sender, address(this), _amount);

        emit Donated(_amount);

    }
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        _safeTransfer(_token, msg.sender, amount);
    }
    function _giveAllowances() internal {
        IERC20(flow).safeApprove(voting_escrow, type(uint256).max);
        IERC20(paymentToken).safeApprove(router, type(uint256).max);
    }
    function _removeAllowances() internal {
        IERC20(flow).safeApprove(voting_escrow, 0);
        IERC20(paymentToken).safeApprove(router, 0);
    }
}