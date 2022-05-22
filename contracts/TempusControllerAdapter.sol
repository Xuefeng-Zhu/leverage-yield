// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ITempusController} from "../interfaces/tempus/ITempusController.sol";
import {ITempusPool} from "../interfaces/tempus/ITempusPool.sol";
import {ICreditManager} from "../interfaces/gearbox/ICreditManager.sol";
import {ICreditFilter} from "../interfaces/gearbox/ICreditFilter.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/math/SafeMathUpgradeable.sol";

contract TempusControllerAdapter {
    using SafeMathUpgradeable for uint256;

    struct ExitAmmParam {
        address tempusAMM;
        ITempusPool tempusPool;
        uint256 lpTokens;
        uint256 principals;
        uint256 yields;
        uint256 minPrincipalsStaked;
        uint256 minYieldsStaked;
        uint256 maxLeftoverShares;
        uint256 yieldsRate;
        uint256 maxSlippage;
        bool toBackingToken;
        uint256 deadline;
    }

    ICreditManager public creditManager;
    ICreditFilter public creditFilter;
    address public controller;

    constructor(
        address _creditManager,
        address _creditFilter,
        address _controller
    ) public {
        creditManager = ICreditManager(_creditManager);
        creditFilter = ICreditFilter(creditManager.creditFilter());
        controller = _controller;
    }

    function depositAndProvideLiquidity(
        address tempusAMM,
        ITempusPool tempusPool,
        uint256 tokenAmount,
        bool isBackingToken
    ) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender);
        address token;

        if (isBackingToken) {
            token = tempusPool.backingToken();
        } else {
            token = tempusPool.yieldBearingToken();
        }

        address[] memory tokenOut = new address[](3);
        tokenOut[0] = tempusPool.principalShare();
        tokenOut[1] = tempusPool.yieldShare();
        tokenOut[2] = tempusAMM;

        uint256[] memory amountOut = new uint256[](3);
        amountOut[0] = IERC20Upgradeable(tokenOut[0]).balanceOf(address(this));
        amountOut[1] = IERC20Upgradeable(tokenOut[1]).balanceOf(address(this));
        amountOut[2] = IERC20Upgradeable(tokenOut[2]).balanceOf(address(this));

        creditManager.provideCreditAccountAllowance(creditAccount, controller, token);

        bytes memory data = abi.encodeWithSelector(
            ITempusController.depositAndProvideLiquidity.selector,
            tempusAMM,
            address(tempusPool),
            tokenAmount,
            isBackingToken
        );

        creditManager.executeOrder(msg.sender, controller, data);

        uint256[] memory amountIn = new uint256[](1);
        amountIn[0] = tokenAmount;
        address[] memory tokenIn = new address[](1);
        tokenIn[0] = token;

        amountOut[0] = IERC20Upgradeable(tokenOut[0]).balanceOf(address(this)).sub(amountOut[0]);
        amountOut[1] = IERC20Upgradeable(tokenOut[1]).balanceOf(address(this)).sub(amountOut[1]);
        amountOut[2] = IERC20Upgradeable(tokenOut[2]).balanceOf(address(this)).sub(amountOut[2]);

        creditFilter.checkMultiTokenCollateral(creditAccount, amountIn, amountOut, tokenIn, tokenOut);
    }

    function depositAndFix(
        address tempusAMM,
        ITempusPool tempusPool,
        uint256 tokenAmount,
        bool isBackingToken,
        uint256 minTYSRate,
        uint256 deadline
    ) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender);
        address token;

        if (isBackingToken) {
            token = tempusPool.backingToken();
        } else {
            token = tempusPool.yieldBearingToken();
        }

        address[] memory tokenOut = new address[](3);
        tokenOut[0] = tempusPool.principalShare();
        tokenOut[1] = tempusPool.yieldShare();
        tokenOut[2] = tempusAMM;

        uint256[] memory amountOut = new uint256[](3);
        amountOut[0] = IERC20Upgradeable(tokenOut[0]).balanceOf(address(this));
        amountOut[1] = IERC20Upgradeable(tokenOut[1]).balanceOf(address(this));
        amountOut[2] = IERC20Upgradeable(tokenOut[2]).balanceOf(address(this));

        creditManager.provideCreditAccountAllowance(creditAccount, controller, token);

        bytes memory data = abi.encodeWithSelector(
            ITempusController.depositAndFix.selector,
            tempusAMM,
            address(tempusPool),
            tokenAmount,
            isBackingToken,
            minTYSRate,
            deadline
        );

        creditManager.executeOrder(msg.sender, controller, data);

        uint256[] memory amountIn = new uint256[](1);
        amountIn[0] = tokenAmount;
        address[] memory tokenIn = new address[](1);
        tokenIn[0] = token;

        amountOut[0] = IERC20Upgradeable(tokenOut[0]).balanceOf(address(this)).sub(amountOut[0]);
        amountOut[1] = IERC20Upgradeable(tokenOut[1]).balanceOf(address(this)).sub(amountOut[1]);
        amountOut[2] = IERC20Upgradeable(tokenOut[2]).balanceOf(address(this)).sub(amountOut[2]);

        creditFilter.checkMultiTokenCollateral(creditAccount, amountIn, amountOut, tokenIn, tokenOut);
    }

    function depositAndLeverage(
        address tempusAMM,
        ITempusPool tempusPool,
        uint256 tokenAmount,
        bool isBackingToken,
        uint256 maxCapitalsRate,
        uint256 deadline
    ) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender);
        address token;

        if (isBackingToken) {
            token = tempusPool.backingToken();
        } else {
            token = tempusPool.yieldBearingToken();
        }

        address[] memory tokenOut = new address[](3);
        tokenOut[0] = tempusPool.principalShare();
        tokenOut[1] = tempusPool.yieldShare();
        tokenOut[2] = tempusAMM;

        uint256[] memory amountOut = new uint256[](3);
        amountOut[0] = IERC20Upgradeable(tokenOut[0]).balanceOf(address(this));
        amountOut[1] = IERC20Upgradeable(tokenOut[1]).balanceOf(address(this));
        amountOut[2] = IERC20Upgradeable(tokenOut[2]).balanceOf(address(this));

        creditManager.provideCreditAccountAllowance(creditAccount, controller, token);

        bytes memory data = abi.encodeWithSelector(
            ITempusController.depositAndLeverage.selector,
            tempusAMM,
            address(tempusPool),
            tokenAmount,
            isBackingToken,
            maxCapitalsRate,
            deadline
        );

        creditManager.executeOrder(msg.sender, controller, data);

        uint256[] memory amountIn = new uint256[](1);
        amountIn[0] = tokenAmount;
        address[] memory tokenIn = new address[](1);
        tokenIn[0] = token;

        amountOut[0] = IERC20Upgradeable(tokenOut[0]).balanceOf(address(this)).sub(amountOut[0]);
        amountOut[1] = IERC20Upgradeable(tokenOut[1]).balanceOf(address(this)).sub(amountOut[1]);
        amountOut[2] = IERC20Upgradeable(tokenOut[2]).balanceOf(address(this)).sub(amountOut[2]);

        creditFilter.checkMultiTokenCollateral(creditAccount, amountIn, amountOut, tokenIn, tokenOut);
    }

    function exitAmmGivenLpAndRedeem(ExitAmmParam calldata exitAmmParam) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender);
        address[] memory tokenOut = new address[](1);

        if (exitAmmParam.toBackingToken) {
            tokenOut[0] = exitAmmParam.tempusPool.backingToken();
        } else {
            tokenOut[0] = exitAmmParam.tempusPool.yieldBearingToken();
        }

        uint256[] memory amountOut = new uint256[](1);
        amountOut[0] = IERC20Upgradeable(tokenOut[0]).balanceOf(address(this));

        address[] memory tokenIn = new address[](3);

        tokenIn[0] = exitAmmParam.tempusAMM;
        tokenIn[1] = exitAmmParam.tempusPool.principalShare();
        tokenIn[2] = exitAmmParam.tempusPool.yieldShare();

        creditManager.provideCreditAccountAllowance(creditAccount, controller, tokenIn[0]);
        creditManager.provideCreditAccountAllowance(creditAccount, controller, tokenIn[1]);
        creditManager.provideCreditAccountAllowance(creditAccount, controller, tokenIn[2]);

        exitAmmGivenLpAndRedeemHelper(exitAmmParam);
        amountOut[0] = IERC20Upgradeable(tokenOut[0]).balanceOf(address(this)).sub(amountOut[0]);

        uint256[] memory amountIn = new uint256[](3);
        amountIn[0] = exitAmmParam.lpTokens;
        amountIn[1] = exitAmmParam.principals;
        amountIn[2] = exitAmmParam.yields;
        creditFilter.checkMultiTokenCollateral(creditAccount, amountIn, amountOut, tokenIn, tokenOut);
    }

    function exitAmmGivenLpAndRedeemHelper(ExitAmmParam calldata exitAmmParam) internal {
        bytes memory data = abi.encodeWithSelector(
            ITempusController.exitAmmGivenLpAndRedeem.selector,
            exitAmmParam.tempusAMM,
            address(exitAmmParam.tempusPool),
            exitAmmParam.lpTokens,
            exitAmmParam.principals,
            exitAmmParam.yields,
            exitAmmParam.minPrincipalsStaked,
            exitAmmParam.minYieldsStaked,
            exitAmmParam.maxLeftoverShares,
            exitAmmParam.yieldsRate,
            exitAmmParam.maxSlippage,
            exitAmmParam.toBackingToken,
            exitAmmParam.deadline
        );
        creditManager.executeOrder(msg.sender, controller, data);
    }
}
