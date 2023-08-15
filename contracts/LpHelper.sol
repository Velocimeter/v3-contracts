// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract LpHelper is Ownable {
    address public router;

    bool public isPaused;

    error LpHelper_Paused();

    event RouterSet(address indexed _router);
    event PauseStateChanged(bool isPaused);

    constructor(address _router, address _team) {
        router = _router;
        _transferOwnership(_team);
    }

    function addLiquidityAndDepositInGauge(
        address account,
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) external {
        if (isPaused) revert LpHelper_Paused();

        _safeTransferFrom(tokenA, msg.sender, address(this), amountADesired);
        _safeTransferFrom(tokenB, msg.sender, address(this), amountBDesired);

        _safeApprove(tokenA, router, amountADesired);
        _safeApprove(tokenB, router, amountBDesired);
        (, , lpAmount) = IRouter(router).addLiquidity(
            tokenA,
            tokenB,
            stable,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            address(this),
            block.timestamp
        );

        // Check gauge for this pair
        address _gauge = IVoter(voter).gauges();
        // DepositFor user
        IGaugeV4(_guage).depositFor(account, lpAmounnt, 0);
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
        emit RouterSet(_router);
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
}
