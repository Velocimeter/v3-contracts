// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import 'openzeppelin-contracts/contracts/utils/math/Math.sol';
import 'contracts/interfaces/IERC20.sol';
import 'contracts/interfaces/IRouter.sol';
import 'contracts/interfaces/IProxyGaugeNotify.sol';
import "openzeppelin-contracts/contracts/access/Ownable.sol";

// Bribes pay out rewards for a given pool based on the votes that were received from the user (goes hand in hand with Voter.vote())
contract ExerciseSortoor is Ownable{
    address public treasury;
    address public veBooster;
    address public router;
    uint256 public ratio = 80; // actual % of how much wftm will swap for FVM

    address public BVM = 0xd386a121991E51Eab5e3433Bf5B1cF4C8884b47a;
    address public wETH = 0x4200000000000000000000000000000000000006;

    mapping(address => bool) public callers;
    
    constructor(address _treasury, address _veBooster, address _router) {
        treasury = _treasury;
        veBooster = _veBooster;
        router = _router;
        giveAllowances();
    }

// ADMINS Set Functions
    function setTreasury(address _treasury) external onlyOwner {
        require (_treasury != address(0));
        treasury = _treasury;
    }
    function setVeBooster(address _booster) external onlyOwner {
        require (_booster != address(0));
        veBooster = _booster;
    }
    function setRouter(address _router) external onlyOwner {
        require (_router != address(0));
        router = _router;
    }
    function setRatio(uint256 _ratio) external onlyOwner {
        ratio = _ratio;
    }

    function setCaller(address _newCaller) external onlyOwner {
        callers[_newCaller] = true;
    }
    function removeCaller(address _newCaller) external onlyOwner {
        callers[_newCaller] = false;
    }
// Public Functions
    function balanceOfBVM() public view returns (uint){
        return IERC20(BVM).balanceOf(address(this));
    }
    function balanceOfWETH() public view returns (uint){
        return IERC20(wETH).balanceOf(address(this));
    }
    function disperse() public {
        require(callers[msg.sender] == true, "You are not allowed to call this");
        uint256 wethBal = balanceOfWETH();
        if (ratio > 0) {
            uint256 wethToSwap = wethBal * ratio / 100;
            IRouter(router).swapExactTokensForTokensSimple(wethToSwap, 1, wETH, BVM, false, address(this), block.timestamp);
            wethBal = balanceOfWETH();
            uint256 BVMBal = balanceOfBVM();
            IProxyGaugeNotify(veBooster).notifyRewardAmount(BVMBal);
        }        
        IERC20(wETH).transfer(treasury, wethBal);
        
    }

// Admin Safety Functions
    function inCaseTokensGetStuck(address _token, address _to) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, amount);
    }
    function giveAllowances() public onlyOwner {
        IERC20(BVM).approve(veBooster, type(uint256).max);
        IERC20(wETH).approve(router, type(uint256).max);
    }
    function removeAllowances() external onlyOwner {
        IERC20(BVM).approve(veBooster, 0);
        IERC20(wETH).approve(router, 0);
    }
}
