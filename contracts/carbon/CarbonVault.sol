// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

import 'contracts/interfaces/carbon/ICarbonController.sol';

contract CarbonVault is ERC20,ReentrancyGuard,IERC721Receiver{

    // The timestamp which users can withdraw their position from carbon
    uint256 public maturity;

    //curent id of the strategy in carbon 
    uint256 public strategyId;

    //
    address public carbonController;
    
    address public tokenToDeposit; 

    address public tokenToBuy;

    bool public initiated; 

    constructor(string memory _name, string memory _symbol, uint256 _maturity,address _tokenToDeposit,address _carbonController) ERC20(_name,_symbol) {
        maturity = _maturity;
        tokenToDeposit = _tokenToDeposit;
        carbonController = _carbonController;
        initiated = false;
    }

    function initStrategy(uint256 _strategyIdToCopy, uint128 _amount) public {
        require(!initiated, "vault started");

        SafeERC20.safeTransferFrom(IERC20(tokenToDeposit), msg.sender, address(this), _amount);

        Strategy memory strategyToCopy = ICarbonController(carbonController).strategy(_strategyIdToCopy);
         
        bool isTargetToken0 = Token.unwrap(strategyToCopy.tokens[0]) == tokenToDeposit;

        tokenToBuy = !isTargetToken0 ? Token.unwrap(strategyToCopy.tokens[0]) : Token.unwrap(strategyToCopy.tokens[1]);

        Order memory mainOrder = isTargetToken0 ? strategyToCopy.orders[0] : strategyToCopy.orders[1];

        mainOrder.y = _amount;
        mainOrder.z = _amount;

        (Order memory targetOrder, Order memory sourceOrder) = isTargetToken0
                ? (mainOrder, strategyToCopy.orders[1])
                : (strategyToCopy.orders[0], mainOrder);

        SafeERC20.safeApprove(IERC20(tokenToDeposit), carbonController, _amount);

        strategyId = ICarbonController(carbonController).createStrategy(strategyToCopy.tokens[0], strategyToCopy.tokens[1], [targetOrder,sourceOrder]);

        _mint(msg.sender, _amount);

        initiated = true;
    }

    function closeStrategy() public {
        require(block.timestamp >= maturity, "vault has not matured");

        if(strategyId != 0) {
            ICarbonController(carbonController).deleteStrategy(strategyId);
            strategyId = 0;
        }
    }

    function deposit(uint128 _amount) public nonReentrant {
        require(strategyId != 0, "vault not started");
        require(block.timestamp < maturity, "vault has matured");

        SafeERC20.safeTransferFrom(IERC20(tokenToDeposit), msg.sender, address(this), _amount);

        Strategy memory strategy = ICarbonController(carbonController).strategy(strategyId);

        bool isTargetToken0 = Token.unwrap(strategy.tokens[0]) == tokenToDeposit;

        Order memory mainOrder = isTargetToken0 ? strategy.orders[0] : strategy.orders[1];

        Order memory updatedMainOrder;
        
        updatedMainOrder.A = mainOrder.A;
        updatedMainOrder.B = mainOrder.B;
        updatedMainOrder.y = mainOrder.y + _amount;
        updatedMainOrder.z = mainOrder.z + _amount;

        (Order memory targetOrder, Order memory sourceOrder) = isTargetToken0
                ? (updatedMainOrder, strategy.orders[1])
                : (strategy.orders[0], updatedMainOrder);

        SafeERC20.safeApprove(IERC20(tokenToDeposit), carbonController, _amount);

        ICarbonController(carbonController).updateStrategy(strategyId, strategy.orders, [targetOrder,sourceOrder]);

        uint256 _amount18 = _to18decimals(tokenToDeposit,_amount); // if the deposit token is not 18 decimals we convert the amout to 18 decimals so 1 share = 1 token

        _mint(msg.sender, _amount18);
    }

    function withdraw(uint256 _shares) public nonReentrant{
        require(block.timestamp >= maturity, "vault has not matured");
        closeStrategy();
        
        // withdraw deposit
        uint depositTokenAmount = (balanceOfDepositToken() * _shares) / totalSupply();
        
        // withdraw executed ammounts 
        uint buyTokenAmount = (balanceOfBuyToken() * _shares) /  totalSupply();

        _burn(msg.sender, _shares);

        if(depositTokenAmount > 0) {
            SafeERC20.safeTransfer(IERC20(tokenToDeposit), msg.sender, depositTokenAmount);
        }

        if(buyTokenAmount > 0) {
            SafeERC20.safeTransfer(IERC20(tokenToBuy), msg.sender, buyTokenAmount);
        }

    }

    function balanceOfDepositToken() public view returns (uint) {
        return IERC20(tokenToDeposit).balanceOf(address(this));
    }

    function balanceOfBuyToken() public view returns (uint) {
        return IERC20(tokenToBuy).balanceOf(address(this));
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