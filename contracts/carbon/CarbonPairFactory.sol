// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import 'contracts/carbon/CarbonPair.sol';
import "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract CarbonPairFactory is Ownable {
    
    address public carbonController;
    address public voter;

    address[] public allPairs;
    mapping(address => bool) public isPair; // only whitelisted ones
    mapping(address => bool) public isCarbonPair; 

    event PairCreated(uint indexed strategyId,uint strategyIdToCopy,address pair);

    constructor(address _carbonController,address _voter) {
        carbonController = _carbonController;
        voter = _voter;
    }

    function whitelistPair (address _pair) external onlyOwner {
        require(isCarbonPair[_pair],"not a carbon pair");
        isPair[_pair] = true;
    }

    function createPair(uint256 _strategyIdToCopy) external returns (address pair) {
        (address token0,address token1,uint token0Amount,uint token1Amount) = carbonBalance(_strategyIdToCopy);


        string memory name = string(abi.encodePacked("Concentrated  Liquidity - ", IERC20Metadata(token0).symbol(), "/", IERC20Metadata(token1).symbol()));
        string memory symbol = string(abi.encodePacked("CL-", IERC20Metadata(token0).symbol(), "/", IERC20Metadata(token1).symbol()));

        CarbonPair cp = new CarbonPair(name,symbol,carbonController,voter);

        if(token0Amount > 0) {
            SafeERC20.safeTransferFrom(IERC20(token0), msg.sender, address(this), token0Amount);
            SafeERC20.safeApprove(IERC20(token0), address(cp), token0Amount);
        }

        if(token1Amount > 0) {
            SafeERC20.safeTransferFrom(IERC20(token1), msg.sender, address(this), token1Amount);
            SafeERC20.safeApprove(IERC20(token1), address(cp), token1Amount);
        }

        cp.initStrategyExactCopy(_strategyIdToCopy);
        
        allPairs.push(address(cp));
        isCarbonPair[address(cp)] = true;

        emit PairCreated(cp.strategyId(),_strategyIdToCopy,address(cp));

        return address(cp);
    }

    function carbonBalance(uint strategyId) public view returns (address,address,uint,uint) {
         Strategy memory strategy = ICarbonController(carbonController).strategy(strategyId);
         
         return (Token.unwrap(strategy.tokens[0]),Token.unwrap(strategy.tokens[1]),strategy.orders[0].y,strategy.orders[1].y);
    }
}