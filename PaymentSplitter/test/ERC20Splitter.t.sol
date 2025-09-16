// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {ERC20Splitter} from "../src/ERC20Splitter.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RareSkillsToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract ERC20SplitterTest is Test {
    ERC20Splitter splitter;
    RareSkillsToken token;
    address owner;
    address[] recipients;
    uint256[] amounts;

    function setUp() public {
        owner = address(this);
        token = new RareSkillsToken("RareSkillsToken", "RST");
        splitter = new ERC20Splitter();

        // Mint tokens to owner
        token.mint(owner, 1000 * 10e18);

        // Approve splitter contract
        token.approve(address(splitter), 1000 * 10e18);

        // Setup recipients and amounts
        recipients = new address[](2);
        recipients[0] = address(0x1);
        recipients[1] = address(0x2);

        amounts = new uint256[](2);
        amounts[0] = 100 * 10e18;
        amounts[1] = 200 * 10e18;
    }

    function testSuccessfulSplit() public {
        splitter.split(token, recipients, amounts);

        assertEq(token.balanceOf(recipients[0]), 100 * 10e18);
        assertEq(token.balanceOf(recipients[1]), 200 * 10e18);
    }

    function testInsufficientApproval() public {
        token.approve(address(splitter), 50 * 10e18);
        vm.expectRevert(ERC20Splitter.InsufficientApproval.selector);
        splitter.split(token, recipients, amounts);
    }

    function testZeroRecipientsAndAmounts() public {
        address[] memory emptyRecipients = new address[](0);
        uint256[] memory emptyAmounts = new uint256[](0);

        splitter.split(token, emptyRecipients, emptyAmounts);
    }

    function testMismatchedArrayLengths() public {
        address[] memory oneRecipient = new address[](1);
        oneRecipient[0] = address(0x1);

        vm.expectRevert(ERC20Splitter.ArrayLengthMismatch.selector);
        splitter.split(token, oneRecipient, amounts);
    }
}