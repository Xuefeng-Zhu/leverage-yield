// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ICreditManager} from "../interfaces/gearbox/ICreditManager.sol";
import {ICreditFilter} from "../interfaces/gearbox/ICreditFilter.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/math/SafeMathUpgradeable.sol";

interface IYVault {
    function token() external view returns (address);

    function deposit() external returns (uint256);

    function deposit(uint256 _amount) external returns (uint256);

    function deposit(uint256 _amount, address recipient) external returns (uint256);

    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);
}

contract YearnAdapter {
    using SafeMathUpgradeable for uint256;

    ICreditManager public creditManager;
    ICreditFilter public creditFilter;

    constructor(
        address _creditManager,
        address _comptroller,
        address _compoundToken
    ) public {
        creditManager = ICreditManager(_creditManager);
        creditFilter = ICreditFilter(creditManager.creditFilter());
    }

    /// @dev Deposit credit account tokens to Yearn
    function deposit(address yVault) external returns (uint256) {
        // bytes4(0xd0e30db0) = deposit()
        return _deposit(yVault, abi.encodeWithSelector(bytes4(0xd0e30db0))); // M:[YA-1]
    }

    /// @dev Deposit credit account tokens to Yearn
    /// @param amount in tokens
    function deposit(address yVault, uint256 amount) external returns (uint256) {
        // bytes4(0xb6b55f25) = deposit
        return _deposit(yVault, abi.encodeWithSelector(bytes4(0xb6b55f25), amount)); // M:[YA-2]
    }

    /// @dev Deposit credit account tokens to Yearn
    /// @param amount in tokens
    function deposit(
        address yVault,
        uint256 amount,
        address
    ) external returns (uint256) {
        // bytes4(0xb6b55f25) = deposit
        return _deposit(yVault, abi.encodeWithSelector(bytes4(0xb6b55f25), amount)); // M:[YA-2]
    }

    function _deposit(address yVault, bytes memory data) internal returns (uint256 shares) {
        address token = IYVault(yVault).token();
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender); // M:[YA-1,2]

        creditManager.provideCreditAccountAllowance(creditAccount, yVault, token); // M:[YA-1,2]

        uint256 balanceInBefore = IERC20Upgradeable(token).balanceOf(creditAccount); // M:[YA-1,2]
        uint256 balanceOutBefore = IERC20Upgradeable(yVault).balanceOf(creditAccount); // M:[YA-1,2]

        shares = abi.decode(creditManager.executeOrder(msg.sender, yVault, data), (uint256)); // M:[YA-1,2]

        creditFilter.checkCollateralChange(
            creditAccount,
            token,
            yVault,
            balanceInBefore.sub(IERC20Upgradeable(token).balanceOf(creditAccount)),
            IERC20Upgradeable(yVault).balanceOf(creditAccount).sub(balanceOutBefore)
        ); // M:[YA-1,2]
    }

    function withdraw(address yVault) external returns (uint256) {
        // bytes4(0x3ccfd60b) = withdraw()
        return _withdraw(yVault, abi.encodeWithSelector(bytes4(0x3ccfd60b))); // M:[YA-3]
    }

    function withdraw(address yVault, uint256 maxShares) external returns (uint256) {
        // bytes4(0x2e1a7d4d) = withdraw(uint256)
        return _withdraw(yVault, abi.encodeWithSelector(bytes4(0x2e1a7d4d), maxShares));
    }

    function withdraw(
        address yVault,
        uint256 maxShares,
        address
    ) external returns (uint256) {
        // Call the function with MaxShares only, cause recepient doesn't make sense here
        // bytes4(0x2e1a7d4d) = withdraw(uint256)
        return _withdraw(yVault, abi.encodeWithSelector(bytes4(0x2e1a7d4d), maxShares));
    }

    /// @dev Withdraw yVaults from credit account
    /// @param maxShares How many shares to try and redeem for tokens, defaults to all.
    //  @param recipient The address to issue the shares in this Vault to. Defaults to the caller's address.
    //  @param maxLoss The maximum acceptable loss to sustain on withdrawal. Defaults to 0.01%.
    //                 If a loss is specified, up to that amount of shares may be burnt to cover losses on withdrawal.
    //  @return The quantity of tokens redeemed for `_shares`.
    function withdraw(
        address yVault,
        uint256 maxShares,
        address,
        uint256 maxLoss
    ) public returns (uint256 shares) {
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender); // M:[YA-3]
        return
            _withdraw(
                yVault,
                abi.encodeWithSelector(
                    bytes4(0xe63697c8), //"withdraw(uint256,address,uint256)",
                    maxShares,
                    creditAccount,
                    maxLoss
                )
            ); // M:[YA-3])
    }

    function _withdraw(address yVault, bytes memory data) internal returns (uint256 shares) {
        address token = IYVault(yVault).token();
        address creditAccount = creditManager.getCreditAccountOrRevert(msg.sender); // M:[YA-3]

        uint256 balanceInBefore = IERC20Upgradeable(yVault).balanceOf(creditAccount); // M:[YA-3]
        uint256 balanceOutBefore = IERC20Upgradeable(token).balanceOf(creditAccount); // M:[YA-3]

        shares = abi.decode(creditManager.executeOrder(msg.sender, yVault, data), (uint256)); // M:[YA-3]

        creditFilter.checkCollateralChange(
            creditAccount,
            yVault,
            token,
            balanceInBefore.sub(IERC20Upgradeable(yVault).balanceOf(creditAccount)),
            IERC20Upgradeable(token).balanceOf(creditAccount).sub(balanceOutBefore)
        ); // M:[YA-3]
    }
}
