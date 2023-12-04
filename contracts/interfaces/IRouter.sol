pragma solidity 0.8.13;

interface IRouter {
    function pairFor(address tokenA, address tokenB, bool stable, address _factory) external view returns (address pair);
}
