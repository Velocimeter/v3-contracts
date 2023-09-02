// SPDX-License-Identifier: MIT

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "contracts/interfaces/IERC20.sol";
import "contracts/interfaces/IVotingEscrow.sol";
import "contracts/interfaces/IVoter.sol";
import "contracts/interfaces/IRouter.sol";
import "contracts/interfaces/IPair.sol";
import "contracts/interfaces/IOptionToken.sol";
import "contracts/interfaces/IBribe.sol";

pragma solidity ^0.8.13;

contract veBuyBribeBooster is Ownable {
    address public paymentToken;
    address public optionToken;
    address public router;
    address public flow;
    address public voting_escrow;
    address public voter;
    uint256 public matchRate = 50; // 50%
    uint256 public maxLock;

    event Boosted(uint256 indexed _timestamp, uint256 _totalLocked, address _locker);
    event Donated(uint256 indexed _timestamp, uint256 _amount);
    event MatchRateChanged(uint256 indexed _timestamp, uint256 _newRate);

    constructor(address _voting_escrow, address _team, address _paymentToken, uint256 _maxLock, address _router,address _optionToken,address _voter) {
        _transferOwnership(_team);
        voting_escrow = _voting_escrow;
        flow = IVotingEscrow(voting_escrow).token();
        paymentToken = _paymentToken;
        maxLock = _maxLock;
        router = _router;
        optionToken = _optionToken;
        voter = _voter;
        _giveAllowances();
    }

    function balanceOfFlow() public view returns (uint){
        return IERC20(flow).balanceOf(address(this));
    }

    function balanceOfOToken() public view returns (uint){
        return IERC20(optionToken).balanceOf(address(this));
    }

    function maxLockableAmount() public view returns (uint){
         uint256 flowBal = balanceOfFlow();
         uint256 amnt = flowBal * 100 / matchRate;
         return amnt;
    }

    function checkFlowBalanceEnough(uint256 _paymentAmount) public view returns (bool) {
        uint256 amount = IRouter(router).getAmountOut(_paymentAmount, paymentToken, flow, false);
        return balanceOfFlow() >= amount * matchRate  / 100;
    }

    function getExpectedAmount(uint256 _paymentAmount) external view returns (uint256) {
        uint256 amount = IRouter(router).getAmountOut(_paymentAmount, paymentToken, flow, false);
        return amount * matchRate  / 100;
    }

    function setMatchRate(uint256 _rate) external onlyOwner {
        require(_rate <= 100, 'cant give more than 1-1');
        matchRate = _rate;  

        emit MatchRateChanged(block.timestamp, matchRate);      
    }
    
    function setPaymentToken(address _paymentToken) external onlyOwner {
        require(_paymentToken != address(0));
        paymentToken = _paymentToken;
    }
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0));
        router = _router;
    }

    function setOptionToken(address _optionToken) external onlyOwner {
        require(_optionToken != address(0));
        optionToken = _optionToken;
    }

    function boostedBuyAndVeLock(uint256 _amount, uint _minOut,address _pool) public {
        require(_amount > 0, 'need to lock at least 1 paymentToken');
        require(balanceOfFlow() > 0, 'no extra FLOW for boosting');
        IERC20(paymentToken).transferFrom(msg.sender, address(this), _amount);

        if (_minOut == 0) {
            _minOut = 1;
        }

        uint256 flowBefore = balanceOfFlow();
        IRouter(router).swapExactTokensForTokensSimple(_amount, _minOut, paymentToken, flow, false, address(this), block.timestamp);
        uint256 flowAfter = balanceOfFlow();
        uint256 flowResult = flowAfter - flowBefore;

        uint256 oTokenBefore = balanceOfOToken();
        IOptionToken(optionToken).mint(address(this), flowResult);
        uint256 oTokenAfter = balanceOfOToken();

        uint256 oTokenResult = oTokenAfter - oTokenBefore;
        
        address gauge = IVoter(voter).gauges(_pool);

        require(IVoter(voter).isAlive(gauge), 'gauge not alive');

        address bribeGauge = IVoter(voter).external_bribes(gauge);

        IERC20(optionToken).approve(bribeGauge, oTokenResult);

        IBribe(bribeGauge).notifyRewardAmount(
                optionToken,
                oTokenResult
        );

        uint256 amountToLock = flowResult * matchRate  / 100;
        IVotingEscrow(voting_escrow).create_lock_for(amountToLock, maxLock, msg.sender);

        emit Boosted(block.timestamp, amountToLock, msg.sender);
    }

    function donateFlow(uint256 _amount) public {
        require(_amount > 0, 'need to add at least 1 FLOW');
        IERC20(flow).transferFrom(msg.sender, address(this), _amount);
        _giveAllowances();
        emit Donated(block.timestamp, _amount);

    }
    function inCaseTokensGetStuck(address _token, address _to) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, amount);
    }
    function _giveAllowances() internal {
        IERC20(flow).approve(voting_escrow, type(uint256).max);
        IERC20(paymentToken).approve(router, type(uint256).max);
        IERC20(flow).approve(optionToken, type(uint256).max);
    }
    function removeAllowances() public onlyOwner {
        IERC20(flow).approve(voting_escrow, 0);
        IERC20(paymentToken).approve(router, 0);
        IERC20(flow).approve(optionToken, 0);
    }
}