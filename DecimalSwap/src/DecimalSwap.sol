// SPDX-License-Identifier: (c) RareSkills
pragma solidity 0.8.28;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


// tokenA and tokenB are stablecoins, so they have the same value, but different
// decimals. This contract allows users to trade one token for another at equal rate
// after correcting for the decimals difference 
contract DecimalSwap {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable tokenA;
    IERC20Metadata public immutable tokenB;

    constructor(address tokenA_, address tokenB_) {
        tokenA = IERC20Metadata(tokenA_);
        tokenB = IERC20Metadata(tokenB_);
    }

    function swapAtoB(uint256 amountIn) external {
        uint256 decimalsA = tokenA.decimals();
        uint256 decimalsB = tokenB.decimals();

        uint256 amountOfB = amountIn * 10 ** decimalsB / 10**decimalsA;
        tokenA.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenB.transfer(msg.sender, amountOfB);
    }

    function swapBtoA(uint256 amountIn) external {
        uint256 decimalsA = tokenA.decimals();
        uint256 decimalsB = tokenB.decimals();

        uint256 amountOfA = amountIn * 10**decimalsA / 10**decimalsB;
        tokenB.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenA.transfer(msg.sender, amountOfA);
    }
}
