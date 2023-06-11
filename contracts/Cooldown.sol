// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


pragma solidity ^0.8.13;

contract Cooldown is ERC20, Ownable, ReentrancyGuard{

    //TO:DO - Convert this to accept flowPLS LPtokens
    // Create notifyRewardAmount() that accepts oFLOW rewards.. and PLS rewards
    // create depositFor(lpBal, _recipient); funtion
    // create interface add import to OptionTokenV2


    IERC20 public FLOW;

    uint256 public constant MAX_COOLDOWN = 604800

    uint256 public cooldown = 172800; //preset to 2 days

    mapping(address => uint256) public blotrToClaim;
    mapping(address => uint256) public wenToClaim;

    constructor(
        IERC20 _blotr,
        string memory _name,
        string memory _symbol) ERC20 (
            string(_name),
            string(_symbol)
        ) {
        BLOTR = _blotr;
    }

    // Stake your BLOTR to earn more BLOTR.
    function stake(uint256 _amount) public nonReentrant {
        uint256 totalBlotr = BLOTR.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalsheep == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount * (totalShares) / (totalBlotr);
            _mint(msg.sender, what);
        }
        BLOTR.transferFrom(msg.sender, address(this), _amount);
    }

    // Burn your sBLOTR to start cooldown to get back BLOTR.
    function sBlotrBurn(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share * (BLOTR.balanceOf(address(this))) / (totalShares);
        _burn(msg.sender, _share);
        blotrToClaim[msg.sender] = what;
        wenToClaim[msg.sender] = block.timestamp + cooldown;
    }
    // Get your BLOTR back
    function getBlotr() public {
        require(block.timestamp >= wenToClaim[msg.sender], "your cooldown is not finished");
        uint256 blotrAmt = blotrToClaim[msg.sender]; 
        BLOTR.transfer(msg.sender, blotrAmt);
    }

    // Owner can adjust the cool down to any block number between 0 - 7 days
    function setCoolDown(uint256 _blocks) public onlyOwner {
        require (_blocks <= MAX_COOLDOWN, "this is too long")
        cooldown = _blocks;
    }

}