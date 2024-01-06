// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {SignedMath} from "openzeppelin-contracts/contracts/utils/math/SignedMath.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IERC20} from "./interfaces/IERC20.sol";
import {IFlow} from "./interfaces/IFlow.sol";
import {IGaugeV2} from "./interfaces/IGaugeV2.sol";
import {IVoter} from "./interfaces/IVoter.sol";
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";
import {IPair} from "./interfaces/IPair.sol";
import {IRouter} from "./interfaces/IRouter.sol";

/// @title Option Token
/// @notice Option token representing the right to purchase the underlying token
/// at TWAP reduced rate. Similar to call options but with a variable strike
/// price that's always at a certain discount to the market price.
/// @dev Assumes the underlying token and the payment token both use 18 decimals and revert on
// failure to transfer.

contract LockDropVeTokenV2 is ERC20, AccessControl {
    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------
    uint256 public constant FULL_LOCK = 52 * 7 * 86400; // 52 weeks

    /// -----------------------------------------------------------------------
    /// Roles
    /// -----------------------------------------------------------------------
    /// @dev The identifier of the role which maintains other roles and settings
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    /// @dev The identifier of the role which is allowed to mint options token
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    /// @dev The identifier of the role which allows accounts to pause execrcising options
    /// in case of emergency
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER");

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------
    error OptionToken_PastDeadline();
    error OptionToken_NoAdminRole();
    error OptionToken_NoMinterRole();
    error OptionToken_NoPauserRole();
    error OptionToken_SlippageTooHigh();
    error OptionToken_InvalidDiscount();
    error OptionToken_InvalidLockDuration();
    error OptionToken_InvalidFee();
    error OptionToken_Paused();
    error OptionToken_InvalidTwapPoints();
    error OptionToken_IncorrectPairToken();
    error VeToggledOff();
    error LpToggledOff();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event ExerciseVe(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 paymentAmount,
        uint256 nftId
    );
    event ExerciseLp(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 paymentAmount,
        uint256 lpAmount
    );
    event SetPairAndPaymentToken(
        IPair indexed newPair,
        address indexed newPaymentToken
    );
    event SetGauge(address indexed newGauge);
    event SetRouter(address indexed newRouter);
    event SetLockDurationForLp(uint256 lockDurationForLp);
    event PauseStateChanged(bool isPaused);
    event veToggledTo(bool veToggle);
    event lpToggledTo(bool lpToggle);


    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The token paid by the options token holder during redemption
    address public paymentToken;

    /// @notice The underlying token purchased during redemption
    address public immutable underlyingToken;

    /// @notice The voting escrow for locking FLOW to veFLOW
    address public immutable votingEscrow;

    /// @notice The voter contract
    address public immutable voter;

 

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------


       /// @notice The router for adding liquidity
    address public router; // this should not be immutable

    /// @notice The pair contract that provides the current TWAP price to purchase
    /// the underlying token while exercising options (the strike price)
    IPair public pair;

    /// @notice The guage contract for the pair
    address public gauge;

    /// @notice the lock duration for to create locked LP
    uint256 public lockDurationForLp =  12 * 7 * 86400; // 12 weeks

    /// @notice Is excersizing options currently paused
    bool public isPaused;

    /// @notice These are for turning on/off the various exercise types
    bool public veToggle = true;
    bool public lpToggle = false;


    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------
    /// @dev A modifier which checks that the caller has the admin role.
    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert OptionToken_NoAdminRole();
        _;
    }

    /// @dev A modifier which checks that the caller has the admin role.
    modifier onlyMinter() {
        if (
            !hasRole(ADMIN_ROLE, msg.sender) &&
            !hasRole(MINTER_ROLE, msg.sender)
        ) revert OptionToken_NoMinterRole();
        _;
    }

    /// @dev A modifier which checks that the caller has the pause role.
    modifier onlyPauser() {
        if (!hasRole(PAUSER_ROLE, msg.sender))
            revert OptionToken_NoPauserRole();
        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        string memory _name,
        string memory _symbol,
        address _admin,
        address _paymentToken,
        address _underlyingToken,
        IPair _pair,
        address _gaugeFactory,
        address _voter,
        address _votingEscrow,
        address _router
    ) ERC20(_name, _symbol, 18) {
        _grantRole(ADMIN_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _gaugeFactory);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);
        paymentToken = _paymentToken;
        underlyingToken = _underlyingToken;
        pair = _pair;
        voter = _voter;
        votingEscrow = _votingEscrow;
        router = _router;

        emit SetPairAndPaymentToken(_pair, paymentToken);
        emit SetRouter(_router);
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Exercises options tokens to purchase the underlying tokens.
    /// @dev The oracle may revert if it cannot give a secure result.
    /// @param _amount The amount of options tokens to exercise
    /// @param _recipient The recipient of the purchased underlying tokens
    /// @param _deadline The Unix timestamp (in seconds) after which the call will revert
    /// @return The amount paid to the treasury to purchase the underlying tokens
    function exerciseVe(
        uint256 _amount,
        address _recipient,
        uint256 _deadline
    ) external returns (uint256, uint256) {
        if (block.timestamp > _deadline) revert OptionToken_PastDeadline();
        return _exerciseVe(_amount, _recipient);
    }

    /// @notice Exercises options tokens to create LP and stake in gauges with lock.
    /// @dev The oracle may revert if it cannot give a secure result.
    /// @param _amount The amount of options tokens to exercise
    /// @param _deadline The Unix timestamp (in seconds) after which the call will revert
    /// @return The amount paid to the treasury to purchase the underlying tokens

    function exerciseLp(
        uint256 _amount,
        address _recipient,
        uint256 _deadline
    ) external returns (uint256, uint256) {
        if (block.timestamp > _deadline) revert OptionToken_PastDeadline();
        return _exerciseLp(_amount, _recipient);
    }

    /// -----------------------------------------------------------------------
    /// Public functions
    /// -----------------------------------------------------------------------


     // @notice Returns the amount in paymentTokens for a given amount of options tokens required for the LP exercise lp
    /// @param _amount The amount of options tokens to exercise
    function getPaymentTokenAmountForExerciseLp(uint256 _amount) public view returns (uint256 paymentAmountToAddLiquidity)
    {
        (uint256 underlyingReserve, uint256 paymentReserve) = IRouter(router).getReserves(underlyingToken, paymentToken, false);
        paymentAmountToAddLiquidity = (_amount * paymentReserve) / underlyingReserve;
    }


    /// -----------------------------------------------------------------------
    /// Admin functions
    /// -----------------------------------------------------------------------

    /// @notice Sets the pair contract. Only callable by the admin.
    /// @param _pair The new pair contract
    function setPairAndPaymentToken(
        IPair _pair,
        address _paymentToken
    ) external onlyAdmin {
        (address token0, address token1) = _pair.tokens();
        if (
            !((token0 == _paymentToken && token1 == underlyingToken) ||
                (token0 == underlyingToken && token1 == _paymentToken))
        ) revert OptionToken_IncorrectPairToken();
        pair = _pair;
        gauge = IVoter(voter).gauges(address(_pair));
        paymentToken = _paymentToken;
        emit SetPairAndPaymentToken(_pair, _paymentToken);
    }

    /// @notice Update gauge address to match with Voter contract
    function updateGauge() external {
        address newGauge = IVoter(voter).gauges(address(pair));
        gauge = newGauge;
        emit SetGauge(newGauge);
    }

    /// @notice Sets the gauge address when the gauge is not listed in Voter. Only callable by the admin.
    /// @param _gauge The new treasury address
    function setGauge(address _gauge) external onlyAdmin {
        gauge = _gauge;
        emit SetGauge(_gauge);
    }

    /// @notice Sets the router address. Only callable by the admin.
    /// @param _router The new router address
    function setRouter(address _router) external onlyAdmin {
        router = _router;
        emit SetRouter(_router);
    }

    /// @notice Sets the lock duration to create LP and stake in gauge. Only callable by the admin.
    /// @param _duration The new lock duration.
    function setLockDurationForLp(
        uint256 _duration
    ) external onlyAdmin {
        lockDurationForLp = _duration;
        emit SetLockDurationForLp(_duration);
    }

    /// @notice Sets which exercise functions can be used.ab
    /// @param _onOff is the state of on / off
    /// @dev This will effect all circulating tokens
    function toggleVe(bool _onOff) external onlyAdmin {
        veToggle = _onOff;
        emit veToggledTo(veToggle);
    }
    function toggleLp(bool _onOff) external onlyAdmin {
        lpToggle = _onOff;
        emit lpToggledTo(lpToggle);
    }


    /// @notice Called by the admin to mint options tokens. Admin must grant token approval.
    /// @param _to The address that will receive the minted options tokens
    /// @param _amount The amount of options tokens that will be minted
    function mint(address _to, uint256 _amount) external onlyMinter {
        // transfer underlying tokens from the caller
        _safeTransferFrom(underlyingToken, msg.sender, address(this), _amount);
        // mint options tokens
        _mint(_to, _amount);
    }


    /// @notice called by the admin to re-enable option exercising from a paused state.
    function unPause() external onlyAdmin {
        if (!isPaused) return;
        isPaused = false;
        emit PauseStateChanged(false);
    }

    /// -----------------------------------------------------------------------
    /// Pauser functions
    /// -----------------------------------------------------------------------
    function pause() external onlyPauser {
        if (isPaused) return;
        isPaused = true;
        emit PauseStateChanged(true);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _exerciseVe(
        uint256 _amount,
        address _recipient
    ) internal returns (uint256 paymentAmount, uint256 nftId) {
        if (isPaused) revert OptionToken_Paused();
        if (!veToggle) revert VeToggledOff();

        // burn callers tokens
        _burn(msg.sender, _amount);

        // lock underlying tokens to veFLOW
        _safeApprove(underlyingToken, votingEscrow, _amount);
        nftId = IVotingEscrow(votingEscrow).create_lock_for(
            _amount,
            FULL_LOCK,
            _recipient
        );

        emit ExerciseVe(msg.sender, _recipient, _amount, paymentAmount, nftId);
    }

    function _exerciseLp(
        uint256 _amount,   // the oTOKEN amount the user wants to redeem with
        address _recipient
    ) internal returns (uint256 paymentAmount, uint256 lpAmount) {
        if (isPaused) revert OptionToken_Paused();
        if (!lpToggle) revert LpToggledOff();

        // burn callers tokens
        _burn(msg.sender, _amount);
        uint256 paymentAmountToAddLiquidity =  getPaymentTokenAmountForExerciseLp(_amount);
          
        _safeTransferFrom(
            paymentToken,
            msg.sender,
            address(this),
            paymentAmountToAddLiquidity
        );

        // Create Lp for users
        _safeApprove(underlyingToken, router, _amount);
        _safeApprove(paymentToken, router, paymentAmountToAddLiquidity);
        (, , lpAmount) = IRouter(router).addLiquidity(
            underlyingToken,
            paymentToken,
            false,
            _amount,
            paymentAmountToAddLiquidity,
            1,
            1,
            address(this),
            block.timestamp
        );

        // Stake the LP in the gauge with lock
        address _gauge = gauge;
        _safeApprove(address(pair), _gauge, lpAmount);
        IGaugeV2(_gauge).depositWithLock(
            _recipient,
            lpAmount,
            lockDurationForLp
        );

        emit ExerciseLp(
            msg.sender,
            _recipient,
            _amount,
            paymentAmount,
            lpAmount
        );
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
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
