pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ITempusController {
    /// @dev Atomically deposits YBT/BT to TempusPool and provides liquidity
    ///      to the corresponding Tempus AMM with the issued TYS & TPS
    /// @param tempusAMM Tempus AMM to use to swap TYS for TPS
    /// @param tempusPool The Tempus Pool to which tokens will be deposited
    /// @param tokenAmount Amount of YBT/BT to be deposited
    /// @param isBackingToken specifies whether the deposited asset is the Backing Token or Yield Bearing Token
    function depositAndProvideLiquidity(
        address tempusAMM,
        address tempusPool,
        uint256 tokenAmount,
        bool isBackingToken
    ) external payable;

    /// @dev Atomically deposits YBT/BT to TempusPool and swaps TYS for TPS to get fixed yield
    ///      See https://docs.balancer.fi/developers/guides/single-swaps#swap-overview
    /// @param tempusAMM Tempus AMM to use to swap TYS for TPS
    /// @param tempusPool The Tempus Pool to which tokens will be deposited
    /// @param tokenAmount Amount of YBT/BT to be deposited in underlying YBT/BT decimal precision
    /// @param isBackingToken specifies whether the deposited asset is the Backing Token or Yield Bearing Token
    /// @param minTYSRate Minimum exchange rate of TYS (denominated in TPS) to receive in exchange for TPS
    /// @param deadline A timestamp by which the transaction must be completed, otherwise it would revert
    /// @return Initial amount of shares minted, before Yields were sold for Capitals
    /// @return Amount of Principal Shares transferred to `msg.sender`
    function depositAndFix(
        address tempusAMM,
        address tempusPool,
        uint256 tokenAmount,
        bool isBackingToken,
        uint256 minTYSRate,
        uint256 deadline
    ) external payable returns (uint256, uint256);

    /// @dev Atomically deposits YBT/BT to TempusPool and swaps Capitals for Yields to get leveraged exposure to yield
    /// @param tempusPool TempusPool to be used for depositing YBT/BT
    /// @param tempusAMM TempusAMM to use to swap Capitals for Yields
    /// @param leverageMultiplier Multiplier to use for leverage, 18 decimal precision. In case of 2x leverage pass 2e18
    /// @param tokenAmount Amount of YBT/BT to be deposited in underlying YBT/BT decimal precision
    /// @param isBackingToken specifies whether the deposited asset is the Backing Token or Yield Bearing Token
    /// @param maxCapitalsRate Maximum exchange rate of Capitals (denominated in Yields) when getting Yield in return
    /// @param deadline A timestamp by which the transaction must be completed, otherwise it would revert
    /// @return Initial amount of shares minted, before Capitals were sold for Yields
    /// @return Amount of Capitals transferred to `msg.sender`
    /// @return Amount of Yields transferred to `msg.sender`
    function depositAndLeverage(
        address tempusAMM,
        address tempusPool,
        uint256 leverageMultiplier,
        uint256 tokenAmount,
        bool isBackingToken,
        uint256 maxCapitalsRate,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @dev Withdraws ALL liquidity from TempusAMM and redeems Shares to Yield Bearing or Backing Tokens
    /// @notice `msg.sender` needs to approve controller for whole balance of LP token
    /// @notice Can fail if there is not enough user balance
    /// @param tempusAMM TempusAMM instance to withdraw liquidity from
    /// @param tempusPool TempusPool instance to withdraw liquidity from
    /// @param lpTokens Number of Lp tokens to redeem
    /// @param principals Number of Principals to redeem
    /// @param yields Number of Yields to redeem
    /// @param minPrincipalsStaked Minimum amount of staked principals to redeem for `lpTokens`
    /// @param minYieldsStaked Minimum amount of staked yields to redeem for `lpTokens`
    /// @param maxLeftoverShares Maximum amount of Principals or Yields to be left in case of early exit
    /// @param yieldsRate Base exchange rate of TYS (denominated in TPS)
    /// @param maxSlippage Maximum allowed change in the exchange rate from the base @param yieldsRate (1e18 precision)
    /// @param toBackingToken If true redeems to backing token, otherwise redeems to yield bearing
    /// @param deadline A timestamp by which, if a swap is necessary, the transaction must be completed,
    ///    otherwise it would revert
    /// @return Amount of Yield Bearing Tokens (if `toBackingToken == false`) or
    ///         Backing Tokens (if `toBackingToken == true`) that were imbursed as a result of the redemption
    function exitAmmGivenLpAndRedeem(
        address tempusAMM,
        address tempusPool,
        uint256 lpTokens,
        uint256 principals,
        uint256 yields,
        uint256 minPrincipalsStaked,
        uint256 minYieldsStaked,
        uint256 maxLeftoverShares,
        uint256 yieldsRate,
        uint256 maxSlippage,
        bool toBackingToken,
        uint256 deadline
    ) external returns (uint256);
}
