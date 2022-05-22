// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {BaseStrategy} from "@badger-finance/BaseStrategy.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/math/SafeMathUpgradeable.sol";

import {ICreditManager, DataTypes} from "../interfaces/gearbox/ICreditManager.sol";
import {CompoundAdapter, ICErc20} from "./CompoundAdapter.sol";

contract CompoundLeverageStrategy is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // address public want; // Inherited from BaseStrategy
    // address public lpComponent; // Token that represents ownership in a pool, not always used
    // address public reward; // Token we farm

    address public constant BADGER = 0x3472A5A71965499acd81997a54BBA8D852C6E53d;
    ICreditManager public constant CREDIT_MANAGER = ICreditManager(0xC38478B0A4bAFE964C3526EEFF534d70E1E09017);

    uint256 public leverageFactor = 400;
    CompoundAdapter public compoundAdapter;
    address public cErc20;
    address public creditAccount;

    /// @dev Initialize the Strategy with security settings as well as tokens
    /// @notice Proxies will set any non constant variable you declare as default value
    /// @dev add any extra changeable variable at end of initializer as shown
    function initialize(
        address _vault,
        address[1] memory _wantConfig,
        CompoundAdapter _compoundAdapter,
        address _cErc20
    ) public initializer {
        __BaseStrategy_init(_vault);
        /// @dev Add config here
        want = _wantConfig[0];
        compoundAdapter = _compoundAdapter;
        cErc20 = _cErc20;

        // If you need to set new values that are not constants, set them like so
        // stakingContract = 0x79ba8b76F61Db3e7D994f7E384ba8f7870A043b7;

        // If you need to do one-off approvals do them here like so
        IERC20Upgradeable(want).safeApprove(address(CREDIT_MANAGER), type(uint256).max);
    }

    /// @dev Return the name of the strategy
    function getName() external pure override returns (string memory) {
        return "CompoundLeverageStrategy";
    }

    /// @dev Return a list of protected tokens
    /// @notice It's very important all tokens that are meant to be in the strategy to be marked as protected
    /// @notice this provides security guarantees to the depositors they can't be sweeped away
    function getProtectedTokens() public view virtual override returns (address[] memory) {
        address[] memory protectedTokens = new address[](2);
        protectedTokens[0] = want;
        protectedTokens[1] = BADGER;
        return protectedTokens;
    }

    /// @dev Deposit `_amount` of want, investing it to earn yield
    function _deposit(uint256 _amount) internal override {
        uint256 mintedAmount = _amount.mul(leverageFactor).div(100);
        if (CREDIT_MANAGER.hasOpenedCreditAccount(address(this))) {
            CREDIT_MANAGER.addCollateral(address(this), want, _amount);
            CREDIT_MANAGER.increaseBorrowedAmount(mintedAmount);
        } else {
            CREDIT_MANAGER.openCreditAccount(_amount, address(this), leverageFactor, 0);
            creditAccount = CREDIT_MANAGER.creditAccounts(address(this));
        }

        compoundAdapter.mint(cErc20, mintedAmount);
    }

    /// @dev Withdraw all funds, this is used for migrations, most of the time for emergency reasons
    function _withdrawAll() internal override {
        compoundAdapter.redeemUnderlying(cErc20, IERC20Upgradeable(cErc20).balanceOf(creditAccount));
        DataTypes.Exchange[] memory paths;
        CREDIT_MANAGER.closeCreditAccount(address(this), paths);
    }

    /// @dev Withdraw `_amount` of want, so that it can be sent to the vault / depositor
    /// @notice just unlock the funds and return the amount you could unlock
    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        _withdrawAll();
        _deposit(IERC20Upgradeable(want).balanceOf(address(this)).sub(_amount));
        return _amount;
    }

    /// @dev Does this function require `tend` to be called?
    function _isTendable() internal pure override returns (bool) {
        return false; // Change to true if the strategy should be tended
    }

    function _harvest() internal override returns (TokenAmount[] memory harvested) {
        // No-op as we don't do anything with funds
        // use autoCompoundRatio here to convert rewards to want ...

        address compoundToken = compoundAdapter.compoundToken();
        uint256 balanceBefore = IERC20Upgradeable(compoundToken).balanceOf(creditAccount);

        compoundAdapter.claimComp();

        // Nothing harvested, we have 2 tokens, return both 0s
        harvested = new TokenAmount[](1);
        harvested[0] = TokenAmount(compoundToken, IERC20Upgradeable(compoundToken).balanceOf(creditAccount).sub(balanceBefore));

        // keep this to get paid!
        _reportToVault(0);

        // Use this if your strategy doesn't sell the extra tokens
        // This will take fees and send the token to the badgerTree
        // _processExtraToken(token, amount);

        return harvested;
    }

    // Example tend is a no-op which returns the values, could also just revert
    function _tend() internal override returns (TokenAmount[] memory tended) {
        // Nothing tended
        return tended;
    }

    /// @dev Return the balance (in want) that the strategy has invested somewhere
    function balanceOfPool() public view override returns (uint256) {
        // Change this to return the amount of want invested in another protocol
        return ICErc20(cErc20).balanceOfUnderlying(creditAccount);
    }

    /// @dev Return the balance of rewards that the strategy has accrued
    /// @notice Used for offChain APY and Harvest Health monitoring
    function balanceOfRewards() external view override returns (TokenAmount[] memory rewards) {
        address compoundToken = compoundAdapter.compoundToken();
        rewards = new TokenAmount[](1);
        rewards[0] = TokenAmount(compoundToken, IERC20Upgradeable(compoundToken).balanceOf(creditAccount));
        return rewards;
    }
}
