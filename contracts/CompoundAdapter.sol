// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ICreditManager} from "../interfaces/gearbox/ICreditManager.sol";
import {ICreditFilter} from "../interfaces/gearbox/ICreditFilter.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/math/SafeMathUpgradeable.sol";

interface ICErc20 {
    /**
     * @notice Accrue interest for `owner` and return the underlying balance.
     *
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Supply ERC20 token to the market, receive cTokens in exchange.
     *
     * @param mintAmount The amount of the underlying asset to supply
     * @return 0 = success, otherwise a failure
     */
    function mint(uint256 mintAmount) external returns (uint256);

    /**
     * @notice Redeem cTokens in exchange for a specified amount of underlying asset.
     *
     * @param redeemAmount The amount of underlying to redeem
     * @return 0 = success, otherwise a failure
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    /**
     * @notice Underlying asset for this CToken
     */
    function underlying() external returns (address);
}

contract CompoundAdapter {
    using SafeMathUpgradeable for uint256;

    ICreditManager public creditManager;
    ICreditFilter public creditFilter;

    constructor(address _creditManager, address _creditFilter) public {
        creditManager = ICreditManager(_creditManager);
        creditFilter = ICreditFilter(creditManager.creditFilter());
    }

    function mint(address cErc20, uint256 amount) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender);
        address underlying = ICErc20(cErc20).underlying();

        address[] memory tokenOut = new address[](1);
        tokenOut[0] = cErc20;
        uint256[] memory amountOut = new uint256[](1);
        amountOut[0] = IERC20Upgradeable(tokenOut[0]).balanceOf(address(this));

        creditManager.provideCreditAccountAllowance(creditAccount, cErc20, underlying);
        bytes memory data = abi.encodeWithSelector(ICErc20.mint.selector, amount);
        creditManager.executeOrder(msg.sender, cErc20, data);

        uint256[] memory amountIn = new uint256[](1);
        amountIn[0] = amount;
        address[] memory tokenIn = new address[](1);
        tokenIn[0] = underlying;
        amountOut[0] = IERC20Upgradeable(tokenOut[0]).balanceOf(address(this)).sub(amountOut[0]);
        creditFilter.checkMultiTokenCollateral(creditAccount, amountIn, amountOut, tokenIn, tokenOut);
    }

    function redeemUnderlying(address cErc20, uint256 amount) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender);
        address underlying = ICErc20(cErc20).underlying();

        address[] memory tokenIn = new address[](1);
        tokenIn[0] = underlying;
        uint256[] memory amountIn = new uint256[](1);
        amountIn[0] = IERC20Upgradeable(tokenIn[0]).balanceOf(address(this));

        bytes memory data = abi.encodeWithSelector(ICErc20.redeemUnderlying.selector, amount);
        creditManager.executeOrder(msg.sender, cErc20, data);

        address[] memory tokenOut = new address[](1);
        tokenOut[0] = cErc20;
        uint256[] memory amountOut = new uint256[](1);
        amountOut[0] = amount;
        amountIn[0] = IERC20Upgradeable(tokenIn[0]).balanceOf(address(this)).sub(amountIn[0]);
        creditFilter.checkMultiTokenCollateral(creditAccount, amountIn, amountOut, tokenIn, tokenOut);
    }
}
