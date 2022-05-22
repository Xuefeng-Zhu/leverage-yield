// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ICreditManager} from "../interfaces/gearbox/ICreditManager.sol";
import {ICreditFilter} from "../interfaces/gearbox/ICreditFilter.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/math/SafeMathUpgradeable.sol";

interface IMarginEngine {
    function underlyingToken() external view returns (address);
}

interface IPeriphery {
    struct MintOrBurnParams {
        IMarginEngine marginEngine;
        int24 tickLower;
        int24 tickUpper;
        uint256 notional;
        bool isMint;
        uint256 marginDelta;
    }

    struct SwapPeripheryParams {
        IMarginEngine marginEngine;
        bool isFT;
        uint256 notional;
        uint160 sqrtPriceLimitX96;
        int24 tickLower;
        int24 tickUpper;
        uint256 marginDelta;
    }

    function mintOrBurn(MintOrBurnParams memory params) external returns (int256 positionMarginRequirement);

    function swap(SwapPeripheryParams memory params)
        external
        returns (
            int256 _fixedTokenDelta,
            int256 _variableTokenDelta,
            uint256 _cumulativeFeeIncurred,
            int256 _fixedTokenDeltaUnbalanced,
            int256 _marginRequirement,
            int24 _tickAfter
        );
}

contract VoltzAdapter {
    using SafeMathUpgradeable for uint256;

    ICreditManager public creditManager;
    ICreditFilter public creditFilter;
    address public periphery;

    constructor(address _creditManager, address _periphery) public {
        creditManager = ICreditManager(_creditManager);
        creditFilter = ICreditFilter(creditManager.creditFilter());
        periphery = _periphery;
    }

    function mintOrBurn(IPeriphery.MintOrBurnParams memory params) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender);
        address underlying = params.marginEngine.underlyingToken();
        uint256 balancerBefore = IERC20Upgradeable(underlying).balanceOf(creditAccount);

        creditManager.provideCreditAccountAllowance(creditAccount, periphery, underlying);
        bytes memory data = abi.encodeWithSelector(IPeriphery.mintOrBurn.selector, params);
        creditManager.executeOrder(msg.sender, periphery, data);

        address[] memory tokenIn;
        uint256[] memory amountIn;
        address[] memory tokenOut;
        uint256[] memory amountOut;

        if (params.isMint) {
            tokenIn = new address[](1);
            tokenIn[0] = underlying;
            amountIn = new uint256[](1);
            amountIn[0] = IERC20Upgradeable(underlying).balanceOf(creditAccount).sub(balancerBefore);
        } else {
            tokenOut = new address[](1);
            tokenOut[0] = underlying;
            amountOut = new uint256[](1);
            amountOut[0] = IERC20Upgradeable(underlying).balanceOf(creditAccount).sub(balancerBefore);
        }
        creditFilter.checkMultiTokenCollateral(creditAccount, amountIn, amountOut, tokenIn, tokenOut);
    }

    function swap(IPeriphery.SwapPeripheryParams memory params) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender);
        address underlying = params.marginEngine.underlyingToken();

        creditManager.provideCreditAccountAllowance(creditAccount, periphery, underlying);
        bytes memory data = abi.encodeWithSelector(IPeriphery.swap.selector, params);
        creditManager.executeOrder(msg.sender, periphery, data);

        address[] memory tokenIn;
        uint256[] memory amountIn;
        address[] memory tokenOut;
        uint256[] memory amountOut;

        creditFilter.checkMultiTokenCollateral(creditAccount, amountIn, amountOut, tokenIn, tokenOut);
    }
}
