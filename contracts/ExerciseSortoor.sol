// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import 'openzeppelin-contracts/contracts/utils/math/Math.sol';
import 'contracts/interfaces/IERC20.sol';
import 'contracts/interfaces/IRouter.sol';
import 'contracts/interfaces/IProxyGaugeNotify.sol';
import 'contracts/interfaces/IBribe.sol';
import "openzeppelin-contracts/contracts/access/Ownable.sol";

// Bribes pay out rewards for a given pool based on the votes that were received from the user (goes hand in hand with Voter.vote())
contract ExerciseSortoor is Ownable{
    address public treasury;
    address public veBooster;
    address public bribe;
    address public router;
    uint256 public ratio = 80; // actual % of how much wftm will swap for FVM

    address public FVM = 0x07BB65fAaC502d4996532F834A1B7ba5dC32Ff96;
    address public wFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    mapping(address => bool) public callers;
    uint256 target;
    uint256 maxGas;

    constructor(address _treasury, address _veBooster, address _bribe, address _router) {
        treasury = _treasury;
        veBooster = _veBooster;
        bribe = _bribe;
        router = _router;
        giveAllowances();
    }

// ADMIN Set Functions
    function setTreasury(address _treasury) external onlyOwner {
        require (_treasury != address(0));
        treasury = _treasury;
    }
    function setVeBooster(address _booster) external onlyOwner {
        require (_booster != address(0));
        veBooster = _booster;
    }
    function setBribe(address _bribe) external onlyOwner {
        require (_bribe != address(0));
        bribe = _bribe;
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
    function setTarget(uint256 _newTarget)external onlyOwner {
        target = _newTarget;
    }
    function setMaxGas(uint256 _newMaxGas)external onlyOwner {
        maxGas = _newMaxGas;
    }

// Public Functions
    function balanceOfFVM() public view returns (uint){
        return IERC20(FVM).balanceOf(address(this));
    }
    function balanceOfWFTM() public view returns (uint){
        return IERC20(wFTM).balanceOf(address(this));
    }
    function checkTargetMet() public view returns (bool canExec){
        if (balanceOfWFTM() > target && tx.gasprice < maxGas) return (true);
    }
    function disperseToBooster() public {
        require(callers[msg.sender], "You are not allowed to call this");
        uint256 wftmBal = balanceOfWFTM();
        if (ratio > 0) {
            uint256 wftmToSwap = wftmBal * ratio / 100;
            IRouter(router).swapExactTokensForTokensSimple(wftmToSwap, 1, wFTM, FVM, false, address(this), block.timestamp);
            wftmBal = balanceOfWFTM();
            uint256 FVMBal = balanceOfFVM();
            IProxyGaugeNotify(veBooster).notifyRewardAmount(FVMBal);
        }        
        IERC20(wFTM).transfer(treasury, wftmBal);        
    }
    function disperseToBribe() public {
        require(callers[msg.sender], "You are not allowed to call this");
        uint256 wftmBal = balanceOfWFTM();
        if (ratio > 0) {
            uint256 wftmToBribe = wftmBal * ratio / 100;
            IBribe(bribe).notifyRewardAmount(wFTM, wftmToBribe);
            wftmBal = balanceOfWFTM();           
        }        
        IERC20(wFTM).transfer(treasury, wftmBal);        
    }

// Admin Safety Functions
    function inCaseTokensGetStuck(address _token, address _to) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, amount);
    }
    function giveAllowances() public onlyOwner {
        IERC20(FVM).approve(veBooster, type(uint256).max);
        IERC20(wFTM).approve(router, type(uint256).max);
    }
    function removeAllowances() external onlyOwner {
        IERC20(FVM).approve(veBooster, 0);
        IERC20(wFTM).approve(router, 0);
    }
}
