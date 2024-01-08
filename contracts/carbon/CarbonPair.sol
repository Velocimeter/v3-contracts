// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

import 'contracts/interfaces/carbon/ICarbonController.sol';

contract CarbonPair is ERC20,ReentrancyGuard,IERC721Receiver{

    //curent id of the strategy in carbon 
    uint256 public strategyId;

    address public carbonController;
    address public voter;

    address public externalBribe;
    bool public hasGauge;
    
    address public token0; 
    address public token1;

    bool public initiated; 

    //errors
    error SlippageTooHigh();

    event Mint(address indexed sender, uint amount0, uint amount1,uint share);
    event Burn(address indexed sender, uint amount0, uint amount1,uint share);

    event ExternalBribeSet(address indexed externalBribe);
    event HasGaugeSet(bool value);

    constructor(string memory _name, string memory _symbol,address _carbonController,address _voter) ERC20(_name,_symbol) {
        carbonController = _carbonController;
        voter = _voter;
        initiated = false;
    }

    function initStrategyExactCopy(uint256 _strategyIdToCopy) public {
        require(!initiated, "vault started");
 
        Strategy memory strategyToCopy = ICarbonController(carbonController).strategy(_strategyIdToCopy);
         
        token0 = Token.unwrap(strategyToCopy.tokens[0]);
        token1 = Token.unwrap(strategyToCopy.tokens[1]);

        Order memory token0Order = strategyToCopy.orders[0]; 
        Order memory token1Order = strategyToCopy.orders[1];

        uint128 amountToken0 =  token0Order.y;
        uint128 amountToken1 =  token1Order.y;

        if(amountToken0 > 0)
            SafeERC20.safeTransferFrom(IERC20(token0), msg.sender, address(this), amountToken0);
        
        if(amountToken1 > 0)
            SafeERC20.safeTransferFrom(IERC20(token1), msg.sender, address(this), amountToken1);

        SafeERC20.safeApprove(IERC20(token0), carbonController, amountToken0);
        SafeERC20.safeApprove(IERC20(token1), carbonController, amountToken1);

        strategyId = ICarbonController(carbonController).createStrategy(strategyToCopy.tokens[0], strategyToCopy.tokens[1], [token0Order,token1Order]);

        uint _amount18Shares = amountToken0 > amountToken1 ? _to18decimals(token0,amountToken0) : _to18decimals(token1,amountToken1);
        _mint(msg.sender, _amount18Shares); // this i start share by defult is base on the amout of token that has higher vaule (first init is 100% of shares)

        initiated = true;
    }

    function initStrategy(uint256 _strategyIdToCopy, uint128 _amountToken0,uint128 _amountToken1) public {
        require(!initiated, "vault started");
        require(_amountToken0 > 0 || _amountToken1 > 0, "amountTokens == 0");
 
        Strategy memory strategyToCopy = ICarbonController(carbonController).strategy(_strategyIdToCopy);
         
        token0 = Token.unwrap(strategyToCopy.tokens[0]);
        token1 = Token.unwrap(strategyToCopy.tokens[1]);

        if(_amountToken0 > 0)
            SafeERC20.safeTransferFrom(IERC20(token0), msg.sender, address(this), _amountToken0);
        
        if(_amountToken1 > 0)
            SafeERC20.safeTransferFrom(IERC20(token1), msg.sender, address(this), _amountToken1);

        Order memory token0Order = strategyToCopy.orders[0]; 
        Order memory token1Order = strategyToCopy.orders[1];

        token0Order.y = _amountToken0;
        token0Order.z = _amountToken0;

        token1Order.y = _amountToken1;
        token1Order.z = _amountToken1;

        SafeERC20.safeApprove(IERC20(token0), carbonController, _amountToken0);
        SafeERC20.safeApprove(IERC20(token1), carbonController, _amountToken1);

        strategyId = ICarbonController(carbonController).createStrategy(strategyToCopy.tokens[0], strategyToCopy.tokens[1], [token0Order,token1Order]);

        uint _amount18Shares = _amountToken0 > _amountToken1 ? _to18decimals(token0,_amountToken0) : _to18decimals(token1,_amountToken1);
        _mint(msg.sender, _amount18Shares); // this i start share by defult is base on the amout of token that has higher vaule (first init is 100% of shares)

        initiated = true;
    }

    function deposit(address tokenToDeposit,uint128 _amount,uint128 _maxAmountSecondToken) public nonReentrant {
        require(strategyId != 0, "vault not started");
        require(tokenToDeposit == token0 || tokenToDeposit == token1, "deposit token is not part of the vault");
        require(_amount > 0, "_amount == 0");

        SafeERC20.safeTransferFrom(IERC20(tokenToDeposit), msg.sender, address(this), _amount);

        Strategy memory strategy = ICarbonController(carbonController).strategy(strategyId);

        bool isTargetToken0 = Token.unwrap(strategy.tokens[0]) == tokenToDeposit;

        address secondTokenAddress =  isTargetToken0 ? Token.unwrap(strategy.tokens[1]) : Token.unwrap(strategy.tokens[0]);

        Order memory targetTokenOrder = isTargetToken0 ? strategy.orders[0] : strategy.orders[1];
        Order memory secondTokenOrder = isTargetToken0 ? strategy.orders[1] : strategy.orders[0];

        require(targetTokenOrder.y > secondTokenOrder.y, "you need to use other token as deposit token"); // defend against precision lost with dust amounts
        
        uint128 _amountSecondToken = (secondTokenOrder.y * _amount) / targetTokenOrder.y;

        if (_amountSecondToken > _maxAmountSecondToken)
            revert SlippageTooHigh();

        if(_amountSecondToken > 0) {
            SafeERC20.safeTransferFrom(IERC20(secondTokenAddress), msg.sender, address(this), _amountSecondToken);
            SafeERC20.safeApprove(IERC20(secondTokenAddress), carbonController, _amountSecondToken);
        }

        uint256 depositShare =  (totalSupply() *  _amount) / targetTokenOrder.y;

        Order memory updatedMainOrder;
        
        updatedMainOrder.A = targetTokenOrder.A;
        updatedMainOrder.B = targetTokenOrder.B;

        updatedMainOrder.z = ((targetTokenOrder.y + _amount) *  targetTokenOrder.z ) / targetTokenOrder.y;
        updatedMainOrder.y = targetTokenOrder.y + _amount;

        
        Order memory updatedSecondOrder; 

        updatedSecondOrder.A = secondTokenOrder.A;
        updatedSecondOrder.B = secondTokenOrder.B;

        if(secondTokenOrder.y > 0 ) { 
            updatedSecondOrder.z = ((secondTokenOrder.y + _amountSecondToken) *  secondTokenOrder.z ) / secondTokenOrder.y;
            updatedSecondOrder.y = secondTokenOrder.y + _amountSecondToken;
        }
        else {
            updatedSecondOrder.z = secondTokenOrder.z;
            updatedSecondOrder.y = secondTokenOrder.y;
        }

        (Order memory targetOrder, Order memory sourceOrder) = isTargetToken0
                ? (updatedMainOrder, updatedSecondOrder)
                : (updatedSecondOrder, updatedMainOrder);

        SafeERC20.safeApprove(IERC20(tokenToDeposit), carbonController, _amount);

        ICarbonController(carbonController).updateStrategy(strategyId, strategy.orders, [targetOrder,sourceOrder]);

        _mint(msg.sender, depositShare);

        emit Mint(msg.sender, _amount, _amountSecondToken,depositShare);
    }

    function withdraw(uint256 _shares) public nonReentrant{
        require(_shares > 0, "_shares == 0");
        
        Strategy memory strategy = ICarbonController(carbonController).strategy(strategyId);

        uint128 token0Amount = uint128((strategy.orders[0].y * _shares) /  totalSupply());
        uint128 token1Amount = uint128((strategy.orders[1].y * _shares) /  totalSupply());

        _burn(msg.sender, _shares);

        require(token0Amount > 0 || token1Amount > 0,"0 to withdraw"); // in case if sombody try to burn small ammount that are lost in the uint256 -> uint128 convert

        Order memory newOrder0;
        
        if(token0Amount >0) {
            newOrder0.A = strategy.orders[0].A;
            newOrder0.B = strategy.orders[0].B;

            newOrder0.z = ((strategy.orders[0].y - token0Amount) *  strategy.orders[0].z ) / strategy.orders[0].y;
            newOrder0.y = strategy.orders[0].y - token0Amount;
        } else {
            newOrder0 = strategy.orders[0];
        }
        
        Order memory newOrder1; 

        if(token1Amount >0) {
            newOrder1.A = strategy.orders[1].A;
            newOrder1.B = strategy.orders[1].B;
        
            newOrder1.z = ((strategy.orders[1].y - token1Amount) *  strategy.orders[1].z ) / strategy.orders[1].y;
            newOrder1.y = strategy.orders[1].y - token1Amount;
        } else {
            newOrder1 = strategy.orders[1];
        }

        ICarbonController(carbonController).updateStrategy(strategyId, strategy.orders, [newOrder0,newOrder1]);

        if(token0Amount > 0) {
            SafeERC20.safeTransfer(IERC20(Token.unwrap(strategy.tokens[0])), msg.sender, token0Amount);
        }

        if(token1Amount > 0) {
            SafeERC20.safeTransfer(IERC20(Token.unwrap(strategy.tokens[1])), msg.sender, token1Amount);
        }

        emit Burn(msg.sender, token0Amount, token1Amount, _shares);
    }

    function carbonBalance() public view returns (address,address,uint,uint) {
         Strategy memory strategy = ICarbonController(carbonController).strategy(strategyId);
         
         return (Token.unwrap(strategy.tokens[0]),Token.unwrap(strategy.tokens[1]),strategy.orders[0].y,strategy.orders[1].y);
    }

    function getSecondTokenAmount(address tokenToDeposit,uint128 _amount) public view returns (uint) {
        Strategy memory strategy = ICarbonController(carbonController).strategy(strategyId);

        bool isTargetToken0 = Token.unwrap(strategy.tokens[0]) == tokenToDeposit;

        address secondTokenAddress =  isTargetToken0 ? Token.unwrap(strategy.tokens[1]) : Token.unwrap(strategy.tokens[0]);

        Order memory targetTokenOrder = isTargetToken0 ? strategy.orders[0] : strategy.orders[1];
        Order memory secondTokenOrder = isTargetToken0 ? strategy.orders[1] : strategy.orders[0];

        return !(targetTokenOrder.y == 0) ?  (secondTokenOrder.y * _amount) / targetTokenOrder.y : 0;
    }

    function balanceOfToken0() public view returns (uint) {
        return IERC20(token0).balanceOf(address(this));
    }

    function balanceOfToken1() public view returns (uint) {
        return IERC20(token1).balanceOf(address(this));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    //functions required by voter
    function setHasGauge(bool value) external {
        require(msg.sender == voter, 'Only voter can set has gauge');
        hasGauge = value;
        emit HasGaugeSet(value);
    }

    function setExternalBribe(address _externalBribe) external {
        require(msg.sender == voter, 'Only voter can set external bribe');
        externalBribe = _externalBribe;
        emit ExternalBribeSet(_externalBribe);
    }

     //precision functions
    function _to18decimals(address _token,uint _amount) internal returns (uint amount)  {
       amount = _amount * 1e18 / 10**IERC20Metadata(_token).decimals();
    }

    function _from18decimals(address _token,uint _amount) internal returns (uint amount,uint amount18decimals) {
       amount = _amount * 10**IERC20Metadata(_token).decimals() / 1e18;
       amount18decimals = _to18decimals(_token,amount); // to cover precision lost
    }
}