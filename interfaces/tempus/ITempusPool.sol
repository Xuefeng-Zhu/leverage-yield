pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ITempusPool {
    function backingToken() external view returns (address);

    function yieldBearingToken() external view returns (address);

    function principalShare() external view returns (address);

    function yieldShare() external view returns (address);
}
