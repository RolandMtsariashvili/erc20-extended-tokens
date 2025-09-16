// SPDX-License-Identifier: (c) RareSkills
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {WETH} from "../src/WETH.sol";

contract WETHTest is Test {
    WETH weth;

    function setUp() public {
        weth = new WETH();
    }

    function test_deposit(address user, uint32 amount) external {
        vm.assume(uint256(uint160(user)) > 1000);
        vm.assume(user.code.length == 0);

        vm.deal(address(user), amount);

        vm.prank(user);
        weth.deposit{value: amount}();

        assertEq(weth.balanceOf(user), amount, "user balance");
        assertEq(weth.totalSupply(), amount, "total supply");
        assertEq(address(weth).balance, amount, "contract balance");
    }

    function test_withdraw(address user, uint32 amount) external {
        vm.assume(uint256(uint160(user)) > 1000);
        vm.assume(user.code.length == 0);

        vm.deal(address(user), amount);
        vm.prank(user);
        weth.deposit{value: amount}();

        vm.prank(user);
        weth.withdraw(amount);

        assertEq(weth.balanceOf(user), 0, "user balance");
        assertEq(weth.totalSupply(), 0, "total supply");
    }

    function test_name() external {
        assertEq(weth.name(), "Wrapped Ether");
    }

    function test_symbol() external {
        assertEq(weth.symbol(), "WETH");
    }

    function test_decimals() external {
        assertEq(weth.decimals(), 18);
    }

    function test_transfer(address user, uint32 amount) external {
        vm.assume(uint256(uint160(user)) > 1000);
        vm.assume(user.code.length == 0);

        vm.deal(address(user), amount);
        vm.prank(user);
        weth.deposit{value: amount}();

        vm.prank(user);
        weth.transfer(address(1010101), amount);

        assertEq(weth.balanceOf(user), 0, "user balance");
        assertEq(weth.balanceOf(address(1010101)), amount, "recipient balance");
    }
}