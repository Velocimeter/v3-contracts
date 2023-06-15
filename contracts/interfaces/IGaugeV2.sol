pragma solidity 0.8.13;

interface IGaugeV2 {
    function notifyRewardAmount(address token, uint amount) external;

    function depositWithLock(
        address account,
        uint256 amount,
        uint256 _lockDuration
    ) external;
}
