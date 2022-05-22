// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ICreditManager {
    function provideCreditAccountAllowance(
        address,
        address,
        address
    ) external;

    function getCreditAccountOrRevert(address) external returns (address);

    function executeOrder(
        address,
        address,
        bytes calldata
    ) external;

    function creditFilter() external view returns (address);
}
