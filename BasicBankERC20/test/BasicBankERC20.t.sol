// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {BasicBankERC20} from "../src/BasicBankERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RareSkillsToken is ERC20 {
    constructor() ERC20("RareSkillsToken", "RST") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract FeeOnTransferToken is ERC20, Ownable(msg.sender) {
    constructor() ERC20("RareSkillsToken", "RST") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 trueAmount = amount * 999 / 1000;
        uint256 fee = amount - trueAmount;
        _update(address(0), owner(), fee);
        return super.transferFrom(from, to, trueAmount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 trueAmount = amount * 999 / 1000;
        uint256 fee = amount - trueAmount;
        _update(address(0), owner(), fee);
        return super.transfer(to, trueAmount);
    }
}

contract BasicBankERC20Test is Test {
    BasicBankERC20 bank;

    address alice = makeAddr("Alice");
    address bob = makeAddr("Bob");

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    function setUp() public {
        bank = new BasicBankERC20();
    }

    function test_deposit() public {
        RareSkillsToken token = new RareSkillsToken();
        token.mint(alice, 1000e18);

        vm.prank(alice);
        token.approve(address(bank), 1000e18);

        vm.prank(alice);
        bank.deposit(address(token), 1000e18);

        assertEq(token.balanceOf(address(bank)), 1000e18);
        assertEq(bank.userTokenBalance(alice, address(token)), 1000e18);
    }

    function test_deposit_event() public {
        RareSkillsToken token = new RareSkillsToken();
        token.mint(alice, 1000e18);

        vm.prank(alice);
        token.approve(address(bank), 1000e18);

        vm.expectEmit();
        emit Deposit(alice, address(token), 1000e18);

        vm.prank(alice);
        bank.deposit(address(token), 1000e18);
    }

    function test_deposit_fee_on_transfer_token() public {
        FeeOnTransferToken token = new FeeOnTransferToken();
        token.mint(alice, 1000e18);

        vm.prank(alice);
        token.approve(address(bank), 1000e18);

        vm.expectRevert(abi.encodeWithSelector(BasicBankERC20.FeeOnTransferNotSupported.selector));
        vm.prank(alice);
        bank.deposit(address(token), 1000e18);
    }

    function test_withdraw() public {
        RareSkillsToken token = new RareSkillsToken();
        token.mint(alice, 1000e18);

        vm.prank(alice);
        token.approve(address(bank), 1000e18);

        vm.prank(alice);
        bank.deposit(address(token), 1000e18);

        vm.prank(alice);
        bank.withdraw(address(token), 1000e18);

        assertEq(token.balanceOf(alice), 1000e18);
        assertEq(token.balanceOf(address(bank)), 0);
    }

    function test_withdraw_event() public {
        RareSkillsToken token = new RareSkillsToken();
        token.mint(alice, 1000e18);

        vm.prank(alice);
        token.approve(address(bank), 1000e18);

        vm.prank(alice);
        bank.deposit(address(token), 1000e18);

        vm.expectEmit();
        emit Withdraw(alice, address(token), 1000e18);

        vm.prank(alice);
        bank.withdraw(address(token), 1000e18);
    }

    function test_withdraw_insufficient_balance() public {
        RareSkillsToken token = new RareSkillsToken();
        token.mint(alice, 1000e18);

        vm.prank(alice);
        token.approve(address(bank), 1000e18);

        vm.prank(alice);
        bank.deposit(address(token), 1000e18);

        vm.expectRevert(abi.encodeWithSelector(BasicBankERC20.InsufficientBalance.selector));
        vm.prank(alice);
        bank.withdraw(address(token), 1000e18 + 1);
    }
}