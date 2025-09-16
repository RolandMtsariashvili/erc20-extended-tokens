// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.28;

import {console, Test} from "forge-std/Test.sol";
import {TokenSale} from "../src/TokenSale.sol";

contract TokenSaleTest is Test {
    TokenSale tokenSale;

    error MaxSupplyReached();

    function setUp() public {
        tokenSale = new TokenSale();
    }
    
    function test_decimals() public {
        assertEq(tokenSale.decimals(), 10);
    }

    function test_buyTokens1() public {
        vm.deal(address(this), 0.001 ether);
        (bool ok, ) = address(tokenSale).call{value: 0.001 ether}("");
        assertTrue(ok);
        assertEq(tokenSale.balanceOf(address(this)), 1e10);
    }

    function test_buyTokens2() public {
        vm.deal(address(this), 0.002 ether);
        (bool ok, ) = address(tokenSale).call{value: 0.002 ether}("");
        assertTrue(ok);
        assertEq(tokenSale.balanceOf(address(this)), 2e10);
    }

    function test_buyTokens_maxSupplyReached() public {
        vm.deal(address(this), 0.001 ether * 100_000_001);
        (bool ok, bytes memory data) = address(tokenSale).call{value: 0.001 ether * 100_000_001}("");
        assertEq(ok, false);
        assertEq(data, abi.encodeWithSignature("MaxSupplyReached()"));
    }
}
