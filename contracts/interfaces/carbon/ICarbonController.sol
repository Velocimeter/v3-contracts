pragma solidity 0.8.13;

struct TradeAction {
    uint256 strategyId;
    uint128 amount;
}

struct Order {
    uint128 y;
    uint128 z;
    uint64 A;
    uint64 B;
}

struct Strategy {
    uint256 id;
    address owner;
    Token[2] tokens;
    Order[2] orders;
}

type Token is address;


interface ICarbonController {
    function tradeBySourceAmount(
        Token sourceToken,
        Token targetToken,
        TradeAction[] calldata tradeActions,
        uint256 deadline,
        uint128 minReturn
    ) external payable returns (uint128);

    function tradeByTargetAmount(
        Token sourceToken,
        Token targetToken,
        TradeAction[] calldata tradeActions,
        uint256 deadline,
        uint128 maxInput
    ) external payable returns (uint128);

    function calculateTradeSourceAmount(
        Token sourceToken,
        Token targetToken,
        TradeAction[] calldata tradeActions
    ) external view returns (uint128);

    function calculateTradeTargetAmount(
        Token sourceToken,
        Token targetToken,
        TradeAction[] calldata tradeActions
    ) external view returns (uint128);

    function createStrategy(
        Token token0,
        Token token1,
        Order[2] calldata orders
    ) external payable returns (uint256);

    function updateStrategy(
        uint256 strategyId,
        Order[2] calldata currentOrders,
        Order[2] calldata newOrders
    ) external payable;

    function deleteStrategy(uint256 strategyId) external;

    function strategy(uint256 id) external view returns (Strategy memory);
}