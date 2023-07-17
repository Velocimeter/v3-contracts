// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import 'contracts/interfaces/IGaugeFactory.sol';
import 'contracts/GaugeV3.sol';
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/access/IAccessControl.sol";
import "contracts/interfaces/ITurnstile.sol";

contract GaugeFactoryV3 is IGaugeFactory, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    address public constant TURNSTILE = 0xEcf044C5B4b867CFda001101c617eCd347095B44;
    uint256 public immutable csrNftId;

    address public last_gauge;
    address public oFlow;

    event OFlowSet(address indexed _oFlow);
    event OFlowUpdatedFor(address indexed _gauge);
    event OTokenAddedFor(address indexed _gauge,address indexed _oToken);
    event OTokenRemovedFor(address indexed _gauge,address indexed _oToken);

    constructor(uint256 _csrNftId) {
        ITurnstile(TURNSTILE).assign(_csrNftId);
        csrNftId = _csrNftId;
    }

    function createGauge(address _pool, address _external_bribe, address _ve, bool isPair, address[] memory allowedRewards) external returns (address) {
        last_gauge = address(new GaugeV3(_pool, _external_bribe, _ve, msg.sender, oFlow, address(this), isPair, allowedRewards, csrNftId));
        if (oFlow != address(0)) {
            IAccessControl(oFlow).grantRole(MINTER_ROLE, last_gauge);
        }
        return last_gauge;
    }

    function setOFlow(address _oFlow) external onlyOwner {
        oFlow = _oFlow;
        emit OFlowSet(_oFlow);
    }

    function updateOFlowFor(address _gauge) external onlyOwner {
        GaugeV3(_gauge).setOFlow(oFlow);
        emit OFlowUpdatedFor(_gauge);
    }

    function addOTokenFor(address _gauge,address _oToken) external onlyOwner{
        GaugeV3(_gauge).addOToken(_oToken);
        emit OTokenAddedFor(_gauge,_oToken);
    }

    function removeOTokenFor(address _gauge,address _oToken) external onlyOwner{
        GaugeV3(_gauge).removeOToken(_oToken);
        emit OTokenRemovedFor(_gauge,_oToken);
    }
}
