// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IOptionToken.sol";
import "../interfaces/IProxyGaugeNotify.sol";

struct PairRewards {
        address reward;
        uint256 amount;
}

contract CarbonRewards is ReentrancyGuard,IProxyGaugeNotify {

    using SafeERC20 for IERC20;

    uint256 constant public PRECISION = 1000;
    uint internal constant DURATION = 7 days; // rewards are released over 7 days

    address public owner;
    address public rewarder;
    
    address public flow;
    address public optionToken;
        
    mapping(address => mapping(address => uint256)) public claimableAmount; // user address to rewards amount mapping

    mapping(address => uint128) public gauges; // mapping of proxy gauge to the pairId 

    mapping(uint128 => address) public pairs; // mapping of proxy gauge to the pairId 

    mapping(uint128 => mapping(uint256 => PairRewards[])) public pairRewards; // pairId => ( epoch => pairRewards)

    mapping(address => uint256) public left; // amout of specific reward tokens left to be distriubted 

    address[] public rewards;
    mapping(address => bool) public isReward;

    modifier onlyOwner {
        require(msg.sender == owner, 'not owner');
        _;
    }

    modifier onlyRewarder {
        require(msg.sender == rewarder, 'not rewarder');
        _;
    }

    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event Claimed(address _who, uint amount);

    event RewardsAdded(uint256 indexed _timestamp,address _reward,uint256 _amount);


    constructor(address _flow, address _optionToken, address _rewarder) {
        owner = msg.sender;

        flow = _flow;
        optionToken = _optionToken;
        rewarder = _rewarder;
    }

    /* 
        OWNER FUNCTIONS
    */

    function setOwner(address _owner) external onlyOwner{
        require(_owner != address(0));
        owner = _owner;
    }

    function setRewarder(address _rewarder) external onlyOwner{
        require(_rewarder != address(0));
        rewarder = _rewarder;
    }

    function addProxyGauge(address proxyGauge,uint128 pairId) external onlyOwner{
        require(gauges[proxyGauge] == 0); 
        gauges[proxyGauge] = pairId;
        pairs[pairId] = proxyGauge;
    }

    function removeProxyGauge(address proxyGauge) external onlyOwner {
        pairs[gauges[proxyGauge]] = address(0);
        gauges[proxyGauge] = 0;
    }

    function setRewardsReceivers(address[] memory _who, uint256[] memory _amount,address _reward) external onlyRewarder {
        require(_who.length == _amount.length);

        for (uint i = 0; i < _who.length; i++) {
            claimableAmount[_who[i]][_reward] += _amount[i];
            left[_reward] -= _amount[i]; // we want code to revert in case if there is no rewards in the system
        }
    }

    function claim(address _reward) public nonReentrant {
        require(claimableAmount[msg.sender][_reward] != 0, "No rewards available");

        uint amount = claimableAmount[msg.sender][_reward];
        claimableAmount[msg.sender][_reward] = 0;

        if(_reward == flow) {
            IERC20(flow).safeApprove(optionToken, amount);
            IOptionToken(optionToken).mint(msg.sender, amount);
        } else {
            IERC20(_reward).safeTransfer(msg.sender, amount);
        }
    }

    function claimMany(address[] memory _tokens) external nonReentrant {
        for (uint i = 0; i < _tokens.length; i++) {
            claim(_tokens[i]);
        }
    }


    function claimable(address user,address reward) public view returns(uint _claimable){
        _claimable = claimableAmount[user][reward];
    }

    function rewardsLength(uint128 _pairId,uint256 _epoch) external view returns (uint) {
        return pairRewards[_pairId][_epoch].length;
    }

    function notifyRewardAmount(uint256 _amount) external { // Proxy Gauge
        require(_amount > 0, 'need to add at least 1 FLOW');
        require(gauges[msg.sender] != 0,"not a proxy gauge");

        uint128 pairId = gauges[msg.sender];

        _addRewards(pairId,_amount,flow);
    }

    function notifyRewardAmount(uint128 pairId,uint256 _amount,address _reward) external onlyOwner { 
        require(_amount > 0, 'need to add at least 1 token');

        _addRewards(pairId,_amount,_reward);
    }

    function getPairRewards(uint128 _pairId,uint256 _epoch) external view returns (PairRewards[] memory) {
        return pairRewards[_pairId][_epoch];
    }

    function _addRewards(uint128 pairId,uint256 _amount,address _reward) internal {
         IERC20(_reward).safeTransferFrom(msg.sender, address(this), _amount);
         uint256 currentEpoch = epoch();
         PairRewards memory pr = PairRewards({ reward: _reward, amount: _amount });
         pairRewards[pairId][currentEpoch].push(pr);
         left[_reward] += _amount;
         if (!isReward[_reward]) {
            isReward[_reward] = true;
            rewards.push(_reward);
         }
         emit RewardsAdded(block.timestamp,_reward,_amount);
    }

    function epoch() public view returns (uint256) {
       return (block.timestamp / DURATION) * DURATION;
    }
    
    function emergencyWithdraw(address _token, uint amount) onlyOwner external{
        IERC20(_token).safeTransfer(owner, amount);

        emit Withdraw(amount);
    }

    function rewardsListLength() external view returns (uint) {
        return rewards.length;
    }
}