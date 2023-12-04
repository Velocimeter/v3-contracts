// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import 'openzeppelin-contracts/contracts/utils/math/Math.sol';
import 'contracts/interfaces/IERC20.sol';
import 'contracts/interfaces/IPair.sol';
import 'contracts/interfaces/IPairFactory.sol';
import 'contracts/interfaces/IRouter.sol';
import 'contracts/interfaces/IWETH.sol';

contract Router is IRouter {

    struct route {
        address from;
        address to;
        bool stable;
        address factory;
    }

    struct RemoveLiquidityETHParams {
        address token;
        bool stable;
        address factory;
        uint liquidity;
        uint amountTokenMin;
        uint amountETHMin;
        address to;
        uint deadline;
    }

    struct RemoveLiquidityParams {
        address tokenA;
        address tokenB;
        bool stable;
        address factory;
        uint liquidity;
        uint amountAMin;
        uint amountBMin;
        address to;
        uint deadline;
    }

    address public immutable factory; // default factory
    IWETH public immutable weth;
    uint internal constant MINIMUM_LIQUIDITY = 10**3;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _weth) {
        factory = _factory;
        weth = IWETH(_weth);
    }

    receive() external payable {
        assert(msg.sender == address(weth)); // only accept ETH via fallback from the WETH contract
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'Router: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Router: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB, bool stable, address _factory) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            _factory,
            keccak256(abi.encodePacked(token0, token1, stable)),
            IPairFactory(_factory).pairCodeHash() // init code hash
        )))));
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quoteLiquidity(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'Router: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'Router: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB, bool stable, address _factory) public view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPair(pairFor(tokenA, tokenB, stable, _factory)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut, address _factory) public view returns (uint amount, bool stable) {
        address pair = pairFor(tokenIn, tokenOut, true, _factory);
        uint amountStable;
        uint amountVolatile;
        if (IPairFactory(_factory).isPair(pair)) {
            amountStable = IPair(pair).getAmountOut(amountIn, tokenIn);
        }
        pair = pairFor(tokenIn, tokenOut, false, _factory);
        if (IPairFactory(_factory).isPair(pair)) {
            amountVolatile = IPair(pair).getAmountOut(amountIn, tokenIn);
        }
        return amountStable > amountVolatile ? (amountStable, true) : (amountVolatile, false);
    }

    //@override
    //getAmountOut	:	bool stable
    //Gets exact output for specific pair-type(S|V)
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut, bool stable, address _factory) public view returns (uint amount) {
        address pair = pairFor(tokenIn, tokenOut, stable, _factory);
        if (IPairFactory(_factory).isPair(pair)) {
            amount = IPair(pair).getAmountOut(amountIn, tokenIn);
        }
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint amountIn, route[] memory routes) public view returns (uint[] memory amounts) {
        require(routes.length >= 1, 'Router: INVALID_PATH');
        amounts = new uint[](routes.length+1);
        amounts[0] = amountIn;
        for (uint i = 0; i < routes.length; i++) {
            address _factory = routes[i].factory == address(0) ? factory : routes[i].factory; // default to FessToLpPair
            address pair = pairFor(routes[i].from, routes[i].to, routes[i].stable, _factory);
            if (IPairFactory(_factory).isPair(pair)) {
                amounts[i+1] = IPair(pair).getAmountOut(amounts[i], routes[i].from);
            }
        }
    }

    function isPair(address pair, address _factory) external view returns (bool) {
        return IPairFactory(_factory).isPair(pair);
    }

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint amountADesired,
        uint amountBDesired
    ) external view returns (uint amountA, uint amountB, uint liquidity) {
        // create the pair if it doesn't exist yet
        address _pair = IPairFactory(_factory).getPair(tokenA, tokenB, stable);
        (uint reserveA, uint reserveB) = (0,0);
        uint _totalSupply = 0;
        if (_pair != address(0)) {
            _totalSupply = IERC20(_pair).totalSupply();
            (reserveA, reserveB) = getReserves(tokenA, tokenB, stable, _factory);
        }
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
        } else {

            uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
                liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
            } else {
                uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
                liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
            }
        }
    }

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint liquidity
    ) external view returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        address _pair = IPairFactory(_factory).getPair(tokenA, tokenB, stable);

        if (_pair == address(0)) {
            return (0,0);
        }

        (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable, _factory);
        uint _totalSupply = IERC20(_pair).totalSupply();

        amountA = liquidity * reserveA / _totalSupply; // using balances ensures pro-rata distribution
        amountB = liquidity * reserveB / _totalSupply; // using balances ensures pro-rata distribution

    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        require(amountADesired >= amountAMin);
        require(amountBDesired >= amountBMin);
        // create the pair if it doesn't exist yet
        address _pair = IPairFactory(_factory).getPair(tokenA, tokenB, stable);
        if (_pair == address(0)) {
            _pair = IPairFactory(_factory).createPair(tokenA, tokenB, stable);
        }
        (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable, _factory);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, stable, _factory, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = pairFor(tokenA, tokenB, stable, _factory);
        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        bool stable,
        address _factory,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            address(weth),
            stable,
            _factory,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = pairFor(token, address(weth), stable, _factory);
        _safeTransferFrom(token, msg.sender, pair, amountToken);
        weth.deposit{value: amountETH}();
        assert(weth.transfer(pair, amountETH));
        liquidity = IPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) _safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        RemoveLiquidityParams memory param
    ) public ensure(param.deadline) returns (uint amountA, uint amountB) {
        address pair = pairFor(param.tokenA, param.tokenB, param.stable, param.factory);
        require(IPair(pair).transferFrom(msg.sender, pair, param.liquidity)); // send liquidity to pair
        (uint amount0, uint amount1) = IPair(pair).burn(param.to);
        (address token0,) = sortTokens(param.tokenA, param.tokenB);
        (amountA, amountB) = param.tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= param.amountAMin, 'Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= param.amountBMin, 'Router: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityETH(
        RemoveLiquidityETHParams memory param
    ) public ensure(param.deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            RemoveLiquidityParams(
                param.token,
                address(weth),
                param.stable,
                param.factory,
                param.liquidity,
                param.amountTokenMin,
                param.amountETHMin,
                address(this),
                param.deadline
            )
        );
        _safeTransfer(param.token, param.to, amountToken);
        weth.withdraw(amountETH);
        _safeTransferETH(param.to, amountETH);
    }

    function removeLiquidityWithPermit(
        RemoveLiquidityParams memory param,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB) {
        address pair = pairFor(param.tokenA, param.tokenB, param.stable, param.factory);
        {
            uint value = approveMax ? type(uint).max : param.liquidity;
            IPair(pair).permit(msg.sender, address(this), value, param.deadline, v, r, s);
        }

        (amountA, amountB) = removeLiquidity(param);
    }

    function removeLiquidityETHWithPermit(
        RemoveLiquidityETHParams memory param,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH) {
        address pair = pairFor(param.token, address(weth), param.stable, param.factory);
        uint value = approveMax ? type(uint).max : param.liquidity;
        IPair(pair).permit(msg.sender, address(this), value, param.deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(param);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, route[] memory routes, address _to) internal virtual {
        for (uint i = 0; i < routes.length; i++) {
            (address token0,) = sortTokens(routes[i].from, routes[i].to);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = routes[i].from == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < routes.length - 1 ? pairFor(routes[i+1].from, routes[i+1].to, routes[i+1].stable, routes[i+1].factory) : _to;
            IPair(pairFor(routes[i].from, routes[i].to, routes[i].stable, routes[i].factory)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function swapExactTokensForTokensSimple(
        uint amountIn,
        uint amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address _factory,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        route[] memory routes = new route[](1);
        routes[0].from = tokenFrom;
        routes[0].to = tokenTo;
        routes[0].stable = stable;
        routes[0].factory = _factory;
        amounts = getAmountsOut(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, 'Router: INSUFFICIENT_OUTPUT_AMOUNT');
        _safeTransferFrom(
            routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory), amounts[0]
        );
        _swap(amounts, routes, to);
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = getAmountsOut(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, 'Router: INSUFFICIENT_OUTPUT_AMOUNT');
        _safeTransferFrom(
            routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory), amounts[0]
        );
        _swap(amounts, routes, to);
    }

    function swapExactETHForTokens(uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(routes[0].from == address(weth), 'Router: INVALID_PATH');
        amounts = getAmountsOut(msg.value, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, 'Router: INSUFFICIENT_OUTPUT_AMOUNT');
        weth.deposit{value: amounts[0]}();
        assert(weth.transfer(pairFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory), amounts[0]));
        _swap(amounts, routes, to);
    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(routes[routes.length - 1].to == address(weth), 'Router: INVALID_PATH');
        amounts = getAmountsOut(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, 'Router: INSUFFICIENT_OUTPUT_AMOUNT');
        _safeTransferFrom(
            routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory), amounts[0]
        );
        _swap(amounts, routes, address(this));
        weth.withdraw(amounts[amounts.length - 1]);
        _safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function UNSAFE_swapExactTokensForTokens(
        uint[] memory amounts,
        route[] calldata routes,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory) {
        _safeTransferFrom(routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory), amounts[0]);
        _swap(amounts, routes, to);
        return amounts;
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
