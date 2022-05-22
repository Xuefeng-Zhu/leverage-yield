// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ICreditManager} from "../interfaces/gearbox/ICreditManager.sol";
import {ICreditFilter} from "../interfaces/gearbox/ICreditFilter.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/math/SafeMathUpgradeable.sol";

interface ILiquidityPool {
    function deposit(address beneficiary, uint256 amount) external returns (uint256);

    function signalWithdrawal(uint256 certificateId) external;

    function unSignalWithdrawal(uint256 certificateId) external;

    function withdraw(address beneficiary, uint256 certificateId) external returns (uint256 value);
}

contract LyraAdapter {
    using SafeMathUpgradeable for uint256;

    ICreditManager public creditManager;
    ICreditFilter public creditFilter;
    address public liquidityPool;
    address public quoteAsset;

    constructor(
        address _creditManager,
        address _liquidityPool,
        address _quoteAsset
    ) public {
        creditManager = ICreditManager(_creditManager);
        creditFilter = ICreditFilter(creditManager.creditFilter());
        liquidityPool = _liquidityPool;
        quoteAsset = _quoteAsset;
    }

    function deposit(uint256 amount) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender);

        creditManager.provideCreditAccountAllowance(creditAccount, liquidityPool, quoteAsset);
        bytes memory data = abi.encodeWithSelector(ILiquidityPool.deposit.selector, creditAccount, amount);
        creditManager.executeOrder(msg.sender, liquidityPool, data);

        address[] memory tokenOut;
        uint256[] memory amountOut;
        address[] memory tokenIn = new address[](1);
        tokenIn[0] = quoteAsset;
        uint256[] memory amountIn = new uint256[](1);
        amountIn[0] = amount;
        creditFilter.checkMultiTokenCollateral(creditAccount, amountIn, amountOut, tokenIn, tokenOut);
    }

    function signalWithdrawal(uint256 certificateId) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender);

        bytes memory data = abi.encodeWithSelector(ILiquidityPool.signalWithdrawal.selector, certificateId);
        creditManager.executeOrder(msg.sender, liquidityPool, data);

        address[] memory tokenIn;
        uint256[] memory amountIn;
        address[] memory tokenOut;
        uint256[] memory amountOut;
        creditFilter.checkMultiTokenCollateral(creditAccount, amountIn, amountOut, tokenIn, tokenOut);
    }

    function unSignalWithdrawal(uint256 certificateId) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender);

        bytes memory data = abi.encodeWithSelector(ILiquidityPool.unSignalWithdrawal.selector, certificateId);
        creditManager.executeOrder(msg.sender, liquidityPool, data);

        address[] memory tokenIn;
        uint256[] memory amountIn;
        address[] memory tokenOut;
        uint256[] memory amountOut;
        creditFilter.checkMultiTokenCollateral(creditAccount, amountIn, amountOut, tokenIn, tokenOut);
    }

    function withdraw(uint256 certificateId) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender);

        address[] memory tokenOut = new address[](1);
        tokenOut[0] = quoteAsset;
        uint256[] memory amountOut = new uint256[](1);
        amountOut[0] = IERC20Upgradeable(quoteAsset).balanceOf(creditAccount);

        bytes memory data = abi.encodeWithSelector(ILiquidityPool.withdraw.selector, creditAccount, certificateId);
        creditManager.executeOrder(msg.sender, liquidityPool, data);

        address[] memory tokenIn;
        uint256[] memory amountIn;
        amountOut[0] = IERC20Upgradeable(quoteAsset).balanceOf(creditAccount).sub(amountOut[0]);

        creditFilter.checkMultiTokenCollateral(creditAccount, amountIn, amountOut, tokenIn, tokenOut);
    }
}
