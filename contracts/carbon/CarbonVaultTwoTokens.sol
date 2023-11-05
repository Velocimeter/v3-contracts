// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

import 'contracts/interfaces/carbon/ICarbonController.sol';

contract CarbonVaultTwoTokens is ERC20,ReentrancyGuard,IERC721Receiver{

    // The timestamp which users can withdraw their position from carbon
    uint256 public maturity;

    //curent id of the strategy in carbon 
    uint256 public strategyId;

    address public carbonController;
    
    address public token0; 
    address public token1;

    bool public initiated; 

    //errors
    error SlippageTooHigh();

    constructor(string memory _name, string memory _symbol, uint256 _maturity,address _carbonController) ERC20(_name,_symbol) {
        maturity = _maturity;
        carbonController = _carbonController;
        initiated = false;
    }

    function initStrategy(uint256 _strategyIdToCopy, uint128 _amountToken0,uint128 _amountToken1) public {
        require(!initiated, "vault started");
 
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

    function closeStrategy() public {
        require(block.timestamp >= maturity, "vault has not matured");

        if(strategyId != 0) {
            ICarbonController(carbonController).deleteStrategy(strategyId);
            strategyId = 0;
        }
    }

    function deposit(address tokenToDeposit,uint128 _amount,uint128 _maxAmountSecondToken) public nonReentrant {
        require(strategyId != 0, "vault not started");
        require(block.timestamp < maturity, "vault has matured");
        require(tokenToDeposit == token0 || tokenToDeposit == token1, "deposit token is not part of the vault");

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

        if(_amountSecondToken > 0)
            SafeERC20.safeTransferFrom(IERC20(secondTokenAddress), msg.sender, address(this), _amountSecondToken);

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
            updatedSecondOrder.z = _amountSecondToken;
            updatedSecondOrder.y = _amountSecondToken;
        }

        (Order memory targetOrder, Order memory sourceOrder) = isTargetToken0
                ? (updatedMainOrder, updatedSecondOrder)
                : (updatedSecondOrder, updatedMainOrder);

        SafeERC20.safeApprove(IERC20(tokenToDeposit), carbonController, _amount);
        SafeERC20.safeApprove(IERC20(secondTokenAddress), carbonController, _amountSecondToken);

        ICarbonController(carbonController).updateStrategy(strategyId, strategy.orders, [targetOrder,sourceOrder]);

        _mint(msg.sender, depositShare);
    }

    function withdraw(uint256 _shares) public nonReentrant{
        require(block.timestamp >= maturity, "vault has not matured");
        closeStrategy();
        
        // withdraw deposit
        uint token0Amount = (balanceOfToken0() * _shares) / totalSupply();
        
        // withdraw executed ammounts 
        uint token1Amount = (balanceOfToken1() * _shares) /  totalSupply();

        _burn(msg.sender, _shares);

        if(token0Amount > 0) {
            SafeERC20.safeTransfer(IERC20(token0), msg.sender, token0Amount);
        }

        if(token1Amount > 0) {
            SafeERC20.safeTransfer(IERC20(token1), msg.sender, token1Amount);
        }

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

        return (secondTokenOrder.y * _amount) / targetTokenOrder.y;
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

     //precision functions
    function _to18decimals(address _token,uint _amount) internal returns (uint amount)  {
       amount = _amount * 1e18 / 10**IERC20Metadata(_token).decimals();
    }

    function _from18decimals(address _token,uint _amount) internal returns (uint amount,uint amount18decimals) {
       amount = _amount * 10**IERC20Metadata(_token).decimals() / 1e18;
       amount18decimals = _to18decimals(_token,amount); // to cover precision lost
    }
}