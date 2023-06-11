// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IFlow} from "./interfaces/IFlow.sol";
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";
import {IPair} from "./interfaces/IPair.sol";
import {IRouter} from "./interfaces/IRouter.sol";

/// @title Option Token
/// @notice Option token representing the right to purchase the underlying token
/// at TWAP reduced rate. Similar to call options but with a variable strike
/// price that's always at a certain discount to the market price.
/// @dev Assumes the underlying token and the payment token both use 18 decimals and revert on
// failure to transfer.

contract OptionTokenV2 is ERC20, AccessControl {
    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------
    uint256 public constant MAX_DISCOUNT = 100; // 100%
    uint256 public constant MIN_DISCOUNT = 0; // 0%
    uint256 public constant MAX_TWAP_POINTS = 50; // 25 hours
    uint256 public constant FULL_LOCK = 26 * 7 * 86400; //26 weeks

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
    error OptionToken_Paused();
    error OptionToken_InvalidTwapPoints();
    error OptionToken_IncorrectPairToken();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Exercise(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 paymentAmount
    );
    event ExerciseVe(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 paymentAmount,
        uint256 nftId
    );
    event SetPairAndPaymentToken(
        IPair indexed newPair,
        address indexed newPaymentToken
    );
    event SetTreasury(address indexed newTreasury);
    event SetDiscount(uint256 discount);
    event SetVeDiscount(uint256 veDiscount);
    event SetLpDiscount(uint256 lpDiscount);
    event PauseStateChanged(bool isPaused);
    event SetTwapPoints(uint256 twapPoints);
    event SetCoolDown(address cooldown);

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The token paid by the options token holder during redemption
    ERC20 public paymentToken;

    /// @notice The underlying token purchased during redemption
    ERC20 public immutable underlyingToken;

    /// @notice The voting escrow for locking FLOW to veFLOR
    address public votingEscrow;

    /// @notice The router for adding liquidity
    address public router;

    /// @notice The staking contract for the LP tokens
    address public cooldown;


    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice The pair contract that provides the current TWAP price to purchase
    /// the underlying token while exercising options (the strike price)
    IPair public pair;

    /// @notice The treasury address which receives tokens paid during redemption
    address public treasury;

    /// @notice the discount given during exercising. 30 = user pays 30%
    uint256 public discount;

    /// @notice the further discount for locking to veFLOW
    uint256 public veDiscount;
    
    /// @notice the further discount for making LP
    uint256 public lpDiscount;

    /// @notice controls the duration of the twap used to calculate the strike price
    // each point represents 30 minutes. 4 points = 2 hours
    uint256 public twapPoints = 4;

    /// @notice Is excersizing options currently paused
    bool public isPaused;

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
        ERC20 _paymentToken,
        ERC20 _underlyingToken,
        IPair _pair,
        address _gaugeFactory,
        address _treasury,
        uint256 _discount,
        uint256 _veDiscount,
        uint256 _lpDiscount,
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
        treasury = _treasury;
        discount = _discount;
        veDiscount = _veDiscount;
        lpDiscount = _lpDiscount;
        votingEscrow = _votingEscrow;
        router = _router;

        emit SetPairAndPaymentToken(_pair, address(paymentToken));
        emit SetTreasury(_treasury);
        emit SetDiscount(_discount);
        emit SetVeDiscount(_veDiscount);
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Exercises options tokens to purchase the underlying tokens.
    /// @dev The oracle may revert if it cannot give a secure result.
    /// @param _amount The amount of options tokens to exercise
    /// @param _maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
    /// @param _recipient The recipient of the purchased underlying tokens
    /// @return The amount paid to the treasury to purchase the underlying tokens
    function exercise(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient
    ) external returns (uint256) {
        return _exercise(_amount, _maxPaymentAmount, _recipient);
    }

    /// @notice Exercises options tokens to purchase the underlying tokens.
    /// @dev The oracle may revert if it cannot give a secure result.
    /// @param _amount The amount of options tokens to exercise
    /// @param _maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
    /// @param _recipient The recipient of the purchased underlying tokens
    /// @param _deadline The Unix timestamp (in seconds) after which the call will revert
    /// @return The amount paid to the treasury to purchase the underlying tokens
    function exercise(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient,
        uint256 _deadline
    ) external returns (uint256) {
        if (block.timestamp > _deadline) revert OptionToken_PastDeadline();
        return _exercise(_amount, _maxPaymentAmount, _recipient);
    }

    /// @notice Exercises options tokens to purchase the underlying tokens.
    /// @dev The oracle may revert if it cannot give a secure result.
    /// @param _amount The amount of options tokens to exercise
    /// @param _maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
    /// @param _recipient The recipient of the purchased underlying tokens
    /// @param _deadline The Unix timestamp (in seconds) after which the call will revert
    /// @return The amount paid to the treasury to purchase the underlying tokens
    function exerciseVe(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient,
        uint256 _deadline
    ) external returns (uint256, uint256) {
        if (block.timestamp > _deadline) revert OptionToken_PastDeadline();
        return _exerciseVe(_amount, _maxPaymentAmount, _recipient);
    }
    /// @notice Exercises options tokens to purchase the underlying tokens.
    /// @dev The oracle may revert if it cannot give a secure result.
    /// @param _amount The amount of options tokens to exercise
    /// @param _maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
    /// @param _recipient The recipient of the purchased underlying tokens
    /// @param _deadline The Unix timestamp (in seconds) after which the call will revert
    /// @return The amount paid to the treasury to purchase the underlying tokens
    
    function exerciseLp(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient,
        uint256 _deadline
    ) external returns (uint256, uint256) {
        if (block.timestamp > _deadline) revert OptionToken_PastDeadline();
        return _exerciseLp(_amount, _maxPaymentAmount, _recipient, _deadline);
    }

    /// -----------------------------------------------------------------------
    /// Public functions
    /// -----------------------------------------------------------------------

    /// @notice Returns the discounted price in paymentTokens for a given amount of options tokens
    /// @param _amount The amount of options tokens to exercise
    /// @return The amount of payment tokens to pay to purchase the underlying tokens
    function getDiscountedPrice(uint256 _amount) public view returns (uint256) {
        return (getTimeWeightedAveragePrice(_amount) * discount) / 100;
    }

    /// @notice Returns the discounted price in paymentTokens for a given amount of options tokens redeemed to veFLOW
    /// @param _amount The amount of options tokens to exercise
    /// @return The amount of payment tokens to pay to purchase the underlying tokens
    function getVeDiscountedPrice(
        uint256 _amount
    ) public view returns (uint256) {
        return (getTimeWeightedAveragePrice(_amount) * veDiscount) / 100;
    }

    /// @notice Returns the discounted price in paymentTokens for a given amount of options tokens redeemed to veFLOW
    /// @param _amount The amount of options tokens to exercise
    /// @return The amount of payment tokens to pay to purchase the underlying tokens
    function getLpDiscountedPrice(
        uint256 _amount
    ) public view returns (uint256) {
        return (getTimeWeightedAveragePrice(_amount) * lpDiscount) / 100;
    }

    /// @notice Returns the average price in payment tokens over 2 hours for a given amount of underlying tokens
    /// @param _amount The amount of underlying tokens to purchase
    /// @return The amount of payment tokens
    function getTimeWeightedAveragePrice(
        uint256 _amount
    ) public view returns (uint256) {
        uint256[] memory amtsOut = IPair(pair).prices(
            address(underlyingToken),
            _amount,
            twapPoints
        );
        uint256 len = amtsOut.length;
        uint256 summedAmount;

        for (uint256 i = 0; i < len; i++) {
            summedAmount += amtsOut[i];
        }

        return summedAmount / twapPoints;
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
            !((token0 == _paymentToken && token1 == address(underlyingToken)) ||
                (token0 == address(underlyingToken) && token1 == _paymentToken))
        ) revert OptionToken_IncorrectPairToken();
        pair = _pair;
        paymentToken = ERC20(_paymentToken);
        emit SetPairAndPaymentToken(_pair, _paymentToken);
    }

    /// @notice Sets the treasury address. Only callable by the admin.
    /// @param _treasury The new treasury address
    function setTreasury(address _treasury) external onlyAdmin {
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    /// @notice Sets the discount amount. Only callable by the admin.
    /// @param _discount The new discount amount.
    function setDiscount(uint256 _discount) external onlyAdmin {
        if (_discount > MAX_DISCOUNT || _discount == MIN_DISCOUNT)
            revert OptionToken_InvalidDiscount();
        discount = _discount;
        emit SetDiscount(_discount);
    }

    /// @notice Sets the discount amount for locking. Only callable by the admin.
    /// @param _veDiscount The new discount amount.
    function setVeDiscount(uint256 _veDiscount) external onlyAdmin {
        if (_veDiscount > MAX_DISCOUNT || _veDiscount == MIN_DISCOUNT)
            revert OptionToken_InvalidDiscount();
        veDiscount = _veDiscount;
        emit SetVeDiscount(_veDiscount);
    }
    /// @notice Sets the  discount amount for creating LP in to cooldown staker. Only callable by the admin.
    /// @param _lpDiscount The new discount amount.
    function setLpDiscount(uint256 _lpDiscount) external onlyAdmin {
        if (_lpDiscount > MAX_DISCOUNT || _lpDiscount == MIN_DISCOUNT)
            revert OptionToken_InvalidDiscount();
        lpDiscount = _lpDiscount;
        emit SetLpDiscount(_lpDiscount);
    }
    /// @notice Sets the cooldown staker. Only callable by the admin.
    /// @param _cooldownDiscount The new discount amount.
    function setCoolDown(uint256 _cooldown) external onlyAdmin {
        cooldown = _cooldown;
        emit SetCoolDown(_cooldown);
    }


    /// @notice Sets the twap points. to control the length of our twap
    /// @param _twapPoints The new twap points.
    function setTwapPoints(uint256 _twapPoints) external onlyAdmin {
        if (_twapPoints > MAX_TWAP_POINTS || _twapPoints == 0)
            revert OptionToken_InvalidTwapPoints();
        twapPoints = _twapPoints;
        emit SetTwapPoints(_twapPoints);
    }

    /// @notice Called by the admin to mint options tokens. Admin must grant token approval.
    /// @param _to The address that will receive the minted options tokens
    /// @param _amount The amount of options tokens that will be minted
    function mint(address _to, uint256 _amount) external onlyMinter {
        // transfer underlying tokens from the caller
        underlyingToken.transferFrom(msg.sender, address(this), _amount); // BLOTR reverts on failure
        // mint options tokens
        _mint(_to, _amount);
    }

    /// @notice Called by the admin to burn options tokens and transfer underlying tokens to the caller.
    /// @param _amount The amount of options tokens that will be burned and underlying tokens transferred to the caller
    function burn(uint256 _amount) external onlyAdmin {
        // transfer underlying tokens to the caller
        underlyingToken.transfer(msg.sender, _amount); // BLOTR reverts on failure
        // burn option tokens
        _burn(msg.sender, _amount);
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

    function _exercise(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient
    ) internal returns (uint256 paymentAmount) {
        if (isPaused) revert OptionToken_Paused();

        // burn callers tokens
        _burn(msg.sender, _amount);
        paymentAmount = getDiscountedPrice(_amount);
        if (paymentAmount > _maxPaymentAmount)
            revert OptionToken_SlippageTooHigh();

        // transfer payment tokens from msg.sender to the treasury
        paymentToken.transferFrom(msg.sender, treasury, paymentAmount); // sCANTO reverts on failure

        // send underlying tokens to recipient
        underlyingToken.transfer(_recipient, _amount); // will revert on failure

        emit Exercise(msg.sender, _recipient, _amount, paymentAmount);
    }

    function _exerciseVe(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient
    ) internal returns (uint256 paymentAmount, uint256 nftId) {
        if (isPaused) revert OptionToken_Paused();

        // burn callers tokens
        _burn(msg.sender, _amount);
        paymentAmount = getVeDiscountedPrice(_amount);
        if (paymentAmount > _maxPaymentAmount)
            revert OptionToken_SlippageTooHigh();

        // transfer payment tokens from msg.sender to the treasury
        paymentToken.transferFrom(msg.sender, treasury, paymentAmount); // sCANTO reverts on failure

        // lock underlying tokens to veFLOW
        underlyingToken.approve(votingEscrow, _amount);
        nftId = IVotingEscrow(votingEscrow).create_lock_for(
            _amount,
            FULL_LOCK,
            _recipient
        );

        emit ExerciseVe(msg.sender, _recipient, _amount, paymentAmount, nftId);
    }
    function _exerciseLp(
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient
        uint256 _deadline
    ) internal returns (uint256 paymentAmount, uint256 nftId) {
        if (isPaused) revert OptionToken_Paused();

        // burn callers tokens
        _burn(msg.sender, _amount);
        paymentAmount = getLpDiscountedPrice(_amount);
        if (paymentAmount > _maxPaymentAmount)
            revert OptionToken_SlippageTooHigh();

        // transfer payment tokens from msg.sender to the treasury
        paymentToken.transferFrom(msg.sender, treasury, paymentAmount); // sCANTO reverts on failure

        // CreateLp and stakes in cooldown vault. 
        uint256 _half = _amount / 2;
        uint256 lpBal = IRouter.addLiquidityETH(underlyingToken, false, _half, 1, 1, address(this), _deadline);
        IPair(pair).approve(cooldown, lpBal);
        ICooldown(cooldown).depositFor(lpBal, _recipient);
        uint256 oFlowBal = _mint(address(this), _half);
        _approve(cooldown, oFlowBal);
        ICooldown.notifyRewardAmount(oFlow, oFlowBal);


        emit ExerciseLp(msg.sender, _recipient, _amount, paymentAmount, nftId);
    }
}
