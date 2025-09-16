// SPDX-License-Identifier: (c) RareSkills 2025
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
// Oracle pool is owned by an exchange. They offer to buy and sell WETH for stablecoins
// The price they buy and sell at is dynamically changed based on an onlyOwner function
// Because the price can change at any time, the swap function needs to have some flexibility 
// to handle the price changes, but allow the user to specify how much price change they are willing to accept

// feeBasisPoints is how much of the amount out is taken as a fee. For example, if
// feeBasisPoints is 100, then 1% of the amount out is taken as a fee.
// If someone would have gotten 100 WETH, they would actually get 99 WETH.
contract OraclePool is Ownable2Step {
    using SafeERC20 for IERC20;

    IERC20 public immutable WETH;
    IERC20 public immutable STABLECOIN; // NOTE: has 6 decimals
    uint256 immutable feeBasisPoints;
    uint256 public ethToUSDRate; // 8 decimals. 2000_00000000 -> 1 ETH is 2000 USD.

    error InsufficientReserves();
    error Slippage(); // amountIn is not enough for amountOutMin

    event ExchangeRateUpdated(uint256 oldRate, uint256 newRate);
    event SwapWethToStable(address indexed user, uint256 weth, uint256 stable);
    event SwapStableToWeth(address indexed user, uint256 stable, uint256 weth);

    constructor(
        address _weth,
        address _stablecoin,
        uint256 _feeBasisPoints,
        uint256 _ethToUSDRate) Ownable(msg.sender) {
    }

    /*
     * @notice Buy WETH with stablecoin
     * @param amountStableIn The amount of stablecoin the user wants to spend. Transferred from the user. Transfered from the user.
     * @param amountOutMin The minimum amount of WETH to receive.
     * @revert amountStableIn is not enough for amountOutMin
     * @revert the contract does not have enough WETH to sell
     * @revert cannot transfer stablecoin from user
     * @return amountOut The amount of WETH the user received.
     */
    function buyWETH(uint256 amountStableIn, uint256 amountOutMin) external returns (uint256 amountOut) {
    }

    /* 
     * @notice Sell WETH for stablecoin
     * @param amountIn The amount of WETH the user wants to sell. Transferred from the user.
     * @param amountOutMin The minimum amount of stablecoin to receive.
     * @revert amountIn is not enough for amountOutMin
     * @revert the contract does not have enough stablecoin to sell
     * @revert cannot transfer WETH from user
     * @return amountOut The amount of stablecoin the user received.
     */
    function sellWETH(uint256 amountWethIn, uint256 amountOutMin) external returns (uint256 amountOut) {
    }

    function setExchangeRate(uint256 _ethToUSDRate) external onlyOwner {
    }
}
