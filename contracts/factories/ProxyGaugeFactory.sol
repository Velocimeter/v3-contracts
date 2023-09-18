// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import 'contracts/interfaces/IGaugeFactory.sol';
import 'contracts/GaugeV3.sol';
import 'contracts/ProxyGauge.sol';
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/access/IAccessControl.sol";

contract ProxyGaugeFactory is IGaugeFactory, Ownable {

    address public immutable flow;
    address[] public gauges;
    mapping(address => bool) public isWhitelisted;


    constructor( address _flow) {
        flow = _flow;
    }
 
    function deployGauge(address _notifyAddress) external onlyOwner returns (address) {
        address last_gauge = address(new ProxyGauge(flow,_notifyAddress));
        isWhitelisted[last_gauge] = true;
        return last_gauge;
    } 

    function createGauge(address _pool, address _external_bribe, address _ve, bool isPair, address[] memory allowedRewards) external returns (address) {
        require(isWhitelisted[_pool],"!whitelisted");
        gauges.push(_pool);
        return _pool;
    }

    function whitelist(address _gauge) external onlyOwner {
        isWhitelisted[_gauge] = true;
    }

    function blacklist(address _gauge) external onlyOwner {
        isWhitelisted[_gauge] = false;
    }

}
