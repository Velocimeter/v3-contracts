// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IGaugeV4} from "./interfaces/IGaugeV4.sol";
import {IPairFactory} from "./interfaces/IPairFactory.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {IVoter} from "./interfaces/IVoter.sol";

contract LpHelper is Ownable {
    address public immutable voter;
    address public pairFactory;
    address public router;

    bool public isPaused;

    error LpHelper_Paused();

    event LiquidityAdded(
        address indexed _pair,
        address indexed _for,
        uint256 _lpAmount,
        bool _depositedInGauge
    );
    event PairFactorySet(address indexed _pairFactory);
    event RouterSet(address indexed _router);
    event PauseStateChanged(bool isPaused);

    constructor(
        address _router,
        address _voter,
        address _pairFactory,
        address _team
    ) {
        pairFactory = _pairFactory;
        router = _router;
        voter = _voter;
        _transferOwnership(_team);
    }

    function depositAndStakeInGaugeFor(
        address account,
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        uint deadline
    )
        external
        returns (address _pair, bool _depositedInGauge, uint256 _lpAmount)
    {
        if (isPaused) revert LpHelper_Paused();

        _safeTransferFrom(tokenA, msg.sender, address(this), amountADesired);
        _safeTransferFrom(tokenB, msg.sender, address(this), amountBDesired);

        _safeApprove(tokenA, router, amountADesired);
        _safeApprove(tokenB, router, amountBDesired);
        (, , _lpAmount) = IRouter(router).addLiquidity(
            tokenA,
            tokenB,
            stable,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            address(this),
            deadline
        );

        // Check gauge for this pair
        _pair = IPairFactory(pairFactory).getPair(tokenA, tokenB, stable);
        address _gauge = IVoter(voter).gauges(_pair);
        // DepositFor user
        if (_gauge != address(0)) {
            _safeApprove(_pair, _gauge, _lpAmount);
            IGaugeV4(_gauge).depositFor(account, _lpAmount);
            _depositedInGauge = true;
        }

        emit LiquidityAdded(_pair, account, _lpAmount, _depositedInGauge);
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
        emit RouterSet(_router);
    }

    function setPairFactory(address _pairFactory) external onlyOwner {
        pairFactory = _pairFactory;
        emit PairFactorySet(_pairFactory);
    }

    function unPause() external onlyOwner {
        if (!isPaused) return;
        isPaused = false;
        emit PauseStateChanged(false);
    }

    function pause() external onlyOwner {
        if (isPaused) return;
        isPaused = true;
        emit PauseStateChanged(true);
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function inCaseTokensGetStuck(
        address _token,
        address _to
    ) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, amount);
    }
}