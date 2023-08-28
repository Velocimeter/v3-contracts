// SPDX-License-Identifier: MIT

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "contracts/interfaces/IERC20.sol";
import "contracts/interfaces/IVotingEscrow.sol";
import "contracts/interfaces/IVoter.sol";
import "contracts/interfaces/IBribe.sol";
import "contracts/interfaces/IRouter.sol";
import "contracts/interfaces/IPair.sol";

pragma solidity ^0.8.13;

contract veBribeBooster is Ownable {
    uint256 public constant MAX_TWAP_POINTS = 50; // 25 hours

    address public routeToken; 
    address public flow;
    address public voting_escrow;
    address public voter;
    uint256 public maxLock;
    
    mapping(address => address) public tokenToPair; // maping of the token address to pair
    mapping(address => uint256) public matchRate;
    mapping(address => uint256) public maxCap; // max cap of the flow boost in flow tokens for the specific bribe token 

    /// @notice controls the duration of the twap used to calculate the strike price
    // each point represents 30 minutes. 4 points = 2 hours
    uint256 public twapPoints = 4;

    event Boosted(uint256 indexed _timestamp, uint256 _totalLocked, uint256 _bribeVaule, address _locker);
    event Donated(uint256 indexed _timestamp, uint256 _amount);
    event MatchRateChanged(uint256 indexed _timestamp, uint256 _newRate,address _bribeToken);

    constructor(address _voting_escrow, address _voter, address _team, uint256 _maxLock, address _routeToken,address _routePair,uint256 _matchRate) {
        voting_escrow = _voting_escrow;
        voter = _voter;
        flow = IVotingEscrow(voting_escrow).token();
        maxLock = _maxLock;
        routeToken = _routeToken;
        tokenToPair[_routeToken] = _routePair;
        maxCap[_routeToken] = type(uint256).max;
        matchRate[_routeToken] = _matchRate;
        _giveAllowances();
        _transferOwnership(_team);
    }

    function balanceOfFlow() public view returns (uint){
        return IERC20(flow).balanceOf(address(this));
    }

    function setMatchRate(address _bribeToken,uint256 _rate) external onlyOwner {
        require(_rate <= 100, 'cant give more than 1-1');
        matchRate[_bribeToken] = _rate;  

        emit MatchRateChanged(block.timestamp, _rate,_bribeToken);      
    }

    function whitelist(address _bribeToken,address _pool,uint256 _maxCap,uint256 _matchRate) external onlyOwner {
        require(_matchRate <= 100, 'cant give more than 1-1');

        IPair pool = IPair(_pool);
        address tokenA = pool.token0();
        address tokenB = pool.token1();
        require(tokenA == routeToken || tokenB == routeToken,"routeToken not part of the pair");

        tokenToPair[_bribeToken] = _pool;
        maxCap[_bribeToken] = _maxCap;
        matchRate[_bribeToken] = _matchRate;  
    }

    function blacklist(address _bribeToken) external onlyOwner {
        delete tokenToPair[_bribeToken];
    }

    function boostedBribe(uint256 _amount, address _bribeToken,address _pool) public {
        require(_amount > 0, 'need to bribe at least 1 token');
        require(balanceOfFlow() > 0, 'no extra tokens for boosting');
        require(tokenToPair[_bribeToken] != address(0), 'bribe token not whitlisted for the boost');

        address gauge = IVoter(voter).gauges(_pool);

        require(IVoter(voter).isAlive(gauge), 'gauge not alive');

        address bribeGauge = IVoter(voter).external_bribes(gauge);
        
        IERC20(_bribeToken).transferFrom(msg.sender, address(this), _amount);

        uint256 bribeValue = getTokenValueInFlow(_amount,_bribeToken);
        
        IERC20(_bribeToken).approve(bribeGauge, _amount);

        IBribe(bribeGauge).notifyRewardAmount(
                _bribeToken,
                _amount
        );

        uint256 amountToLock = bribeValue * matchRate[_bribeToken]  / 100 ;

        require(maxCap[_bribeToken] > amountToLock, "maxCap reached");
        maxCap[_bribeToken] -= amountToLock;
        
        IVotingEscrow(voting_escrow).create_lock_for(amountToLock, maxLock, msg.sender);

        emit Boosted(block.timestamp, amountToLock, bribeValue ,msg.sender);
    }

    function getTokenValueInFlow(uint256 _amount,address _token) public view returns (uint256) {
        uint256 _routeTokenAmount = _amount; 

        if(_token != routeToken) { // first we need to get the price in the route token for example ETH
            _routeTokenAmount = getTimeWeightedAveragePrice(_amount,_token); 
        }
        
        return getTimeWeightedAveragePrice(_routeTokenAmount,routeToken); 
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
    }
    function removeAllowances() public onlyOwner {
        IERC20(flow).approve(voting_escrow, 0);
    }

    /// @notice Returns the average price in payment tokens over 2 hours for a given amount of underlying tokens
    /// @param _amount The amount of underlying tokens to purchase
    /// @return The amount of payment tokens
    function getTimeWeightedAveragePrice(
        uint256 _amount,address _token
    ) public view returns (uint256) {
        uint256[] memory amtsOut = IPair(tokenToPair[_token]).prices(
            _token,
            _amount,
            twapPoints
        );
        uint256 len = amtsOut.length;
        uint256 summedAmount;

        for (uint256 i = 0; i < len; i++) {
            summedAmount += amtsOut[i];
        }

        return summedAmount / twapPoints;
    }
}