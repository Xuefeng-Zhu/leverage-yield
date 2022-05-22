pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ICreditFilter {
    function checkMultiTokenCollateral(
        address creditAccount,
        uint256[] memory amountIn,
        uint256[] memory amountOut,
        address[] memory tokenIn,
        address[] memory tokenOut
    ) external;
}
