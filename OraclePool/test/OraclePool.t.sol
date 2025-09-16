// SPDX-License-Identifier: (c) RareSkills 2025
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {OraclePool} from "../src/OraclePool.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USD is ERC20("USD", "USD") {
    constructor() {

    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract WETH is ERC20("WETH", "WETH") {
    constructor() {

    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}   

contract OraclePoolTest is Test {
    OraclePool public oraclePool;
    WETH public weth;
    USD public usd;
    address alice = makeAddr("Alice");

    function setUp() public {
        weth = new WETH();
        usd = new USD();
        uint256 basisPointFee = 10;
        oraclePool = new OraclePool(address(weth), address(usd), basisPointFee, 2000e8); // 8 decimals
    }

    function test_stableToWethCase1() public {
        usd.mint(address(oraclePool), 10_000e6);
        weth.mint(address(oraclePool), 100e18);

        // $4000 ~ 2 ETH
        usd.mint(alice, 4000e6);
        vm.startPrank(alice);
        usd.approve(address(oraclePool), 4000e6);
        uint256 amountWethOut = oraclePool.buyWETH(4000e6, 1.9 ether);
        vm.stopPrank();

        uint256 amountExpected = 2 ether - 2 ether * 10 / 10000;

        assertEq(amountWethOut, amountExpected);
    }

    function test_stableToWethCase2() public {
        usd.mint(address(oraclePool), 10_000e6);
        weth.mint(address(oraclePool), 100e18);

        oraclePool.setExchangeRate(1000e8);

        usd.mint(alice, 4000e6);
        vm.startPrank(alice);
        usd.approve(address(oraclePool), 4000e6);
        uint256 amountWethOut = oraclePool.buyWETH(4000e6, 3.9 ether);
        vm.stopPrank();

        uint256 amountExpected = 4 ether - 4 ether * 10 / 10000;
        assertEq(amountWethOut, amountExpected);
    }

    function test_revert_amountOutNotEnough() public {
        usd.mint(address(oraclePool), 10_000e6);
        weth.mint(address(oraclePool), 100e18);

        usd.mint(alice, 4000e6);
        vm.startPrank(alice);
        usd.approve(address(oraclePool), 4000e6);
        vm.expectRevert(OraclePool.Slippage.selector);
        oraclePool.buyWETH(4000e6, 2 ether + 1 wei);
        vm.stopPrank();
    }

    function test_splippage_within_tolerance() public {
        oraclePool.setExchangeRate(2000e8);

        usd.mint(address(oraclePool), 10_000e6);
        weth.mint(address(oraclePool), 100e18);

        usd.mint(alice, 4000e6);
        vm.prank(alice);
        usd.approve(address(oraclePool), 4000e6);

        // eth price goes up slightly
        oraclePool.setExchangeRate(2002e8);
        
        // alice's transaction should succeed
        vm.prank(alice);
        oraclePool.buyWETH(4000e6, 1.9 ether);
        assertGe(weth.balanceOf(alice), 1.9 ether);
    }

    function test_splippage_exceed_tolerance() public {
        oraclePool.setExchangeRate(2000e8);

        usd.mint(address(oraclePool), 10_000e6);
        weth.mint(address(oraclePool), 100e18);

        usd.mint(alice, 4000e6);
        vm.prank(alice);
        usd.approve(address(oraclePool), 4000e6);

        // eth price goes up slightly
        oraclePool.setExchangeRate(2200e8);
        
        vm.prank(alice);
        vm.expectRevert(OraclePool.Slippage.selector);
        oraclePool.buyWETH(4000e6, 1.9 ether);
    }

    function test_wethToStableCase1() public {
        usd.mint(address(oraclePool), 10_000e6);
        weth.mint(address(oraclePool), 100e18);

        oraclePool.setExchangeRate(2000e8);

        weth.mint(alice, 2 ether);
        vm.startPrank(alice);
        weth.approve(address(oraclePool), 2 ether);

        uint256 amountStableOut = oraclePool.sellWETH(2 ether, 3950e6);
        vm.stopPrank();

        uint256 amountStableOutExpected = 4000e6 - 4000e6 * 10 / 10000;

        assertEq(amountStableOut, amountStableOutExpected);
    }

    function test_wethToStableCase2() public {
        usd.mint(address(oraclePool), 10_000e6);
        weth.mint(address(oraclePool), 100e18);

        oraclePool.setExchangeRate(1000e8);

        weth.mint(alice, 2 ether);
        vm.startPrank(alice);
        weth.approve(address(oraclePool), 2 ether);

        uint256 amountStableOut = oraclePool.sellWETH(2 ether, 1950e6);
        vm.stopPrank();

        uint256 amountStableOutExpected = 2000e6 - 2000e6 * 10 / 10000;

        assertEq(amountStableOut, amountStableOutExpected);
    }

    function test_revert_sellWeth_amountOutNotEnough() public {
        usd.mint(address(oraclePool), 10_000e6);
        weth.mint(address(oraclePool), 100e18);

        oraclePool.setExchangeRate(2000e8);

        weth.mint(alice, 2 ether);
        vm.startPrank(alice);
        weth.approve(address(oraclePool), 2 ether);

        vm.expectRevert(OraclePool.Slippage.selector);
        oraclePool.sellWETH(2 ether, 4000e6);
    }

    function test_event_swapWethToStable() public {
        usd.mint(address(oraclePool), 10_000e6);
        weth.mint(address(oraclePool), 100e18);

        oraclePool.setExchangeRate(2000e8);

        weth.mint(alice, 2 ether);
        vm.startPrank(alice);
        weth.approve(address(oraclePool), 2 ether);

        vm.expectEmit();
        emit OraclePool.SwapWethToStable(alice, 2 ether, 3996000000);
        oraclePool.sellWETH(2 ether, 3000e6);
        vm.stopPrank();
    }

    function test_event_swapStableToWeth() public {
        usd.mint(address(oraclePool), 10_000e6);
        weth.mint(address(oraclePool), 100e18);

        oraclePool.setExchangeRate(2000e8);

        usd.mint(alice, 4000e6);
        vm.startPrank(alice);
        usd.approve(address(oraclePool), 4000e6);

        vm.expectEmit();
        emit OraclePool.SwapStableToWeth(alice, 4000e6, 1998000000000000000);
        oraclePool.buyWETH(4000e6, 1.9 ether);
        vm.stopPrank();
    }

    function test_updateExchangeRate_event() public {
        vm.expectEmit();
        emit OraclePool.ExchangeRateUpdated(2000e8, 2200e8);
        oraclePool.setExchangeRate(2200e8);

        assertEq(oraclePool.ethToUSDRate(), 2200e8);
    }
}