// SPDX-License-Identifier: (c) RareSkills
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DecimalSwap} from "../src/DecimalSwap.sol";

contract TokenA is ERC20("Token A", "A") {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}

contract TokenB is ERC20("Token B", "B") {

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract DecimalSwapTest is Test {
    DecimalSwap public swap;
    TokenA public tokenA;
    TokenB public tokenB;

    function setUp() public {
        tokenA = new TokenA();
        tokenB = new TokenB();
        swap = new DecimalSwap(address(tokenA), address(tokenB));

        tokenA.mint(address(swap), 1_000_000 * 10 ** 18);
        tokenB.mint(address(swap), 1_000_000 * 10 ** 6);
    }

    function test_swapAtoB() public {
        tokenA.mint(address(this), 1000e18);
        tokenA.approve(address(swap), 1000e18);
        swap.swapAtoB(1000e18);
        assertEq(tokenB.balanceOf(address(this)), 1000e6);
    }

    function test_swapBtoA() public {
        tokenB.mint(address(this), 1000e6);
        tokenB.approve(address(swap), 1000e6);
        swap.swapBtoA(1000e6);
        assertEq(tokenA.balanceOf(address(this)), 1000e18);
    }
}
