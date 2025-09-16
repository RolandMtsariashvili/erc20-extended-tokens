// SPDX-License-Identifier: (c) RareSkills
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {WeeklySalary} from "../src/WeeklySalary.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RareSkillsToken is ERC20 {
    constructor() ERC20("RareSkillsToken", "RST") {

    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract WeeklySalaryTest is Test {
    RareSkillsToken rareSkillsToken;
    WeeklySalary weeklySalary;

    function setUp() public {
        rareSkillsToken = new RareSkillsToken();
        weeklySalary = new WeeklySalary(address(rareSkillsToken));
    }

    function test_createContractor() public {
        address bob = makeAddr("bob");

        rareSkillsToken.mint(address(weeklySalary), 1000e18);
        weeklySalary.createContractor(bob, 1000e18);

        (uint256 weeklySalaryAmount, uint256 lastWithdrawal) = weeklySalary.contractors(bob);
        assertEq(weeklySalaryAmount, 1000e18);
        assertEq(lastWithdrawal, block.timestamp);
    }

    function test_onlyOwnerCanCreateContractor(address hacker) public {
        vm.assume(hacker != weeklySalary.owner());
        vm.prank(hacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", hacker));
        weeklySalary.createContractor(hacker, 1000e18);
    }

    function test_createContractor_revertsIfWeeklySalaryIsZero() public {
        address bob = makeAddr("bob");
        vm.prank(weeklySalary.owner());
        vm.expectRevert(abi.encodeWithSignature("InvalidWeeklySalary()"));
        weeklySalary.createContractor(bob, 0);
    }

    function test_createContractor_revertsIfContractorAlreadyExists() public {
        address bob = makeAddr("bob");
        vm.prank(weeklySalary.owner());
        weeklySalary.createContractor(bob, 1000e18);

        vm.prank(weeklySalary.owner());
        vm.expectRevert(abi.encodeWithSignature("ContractorAlreadyExists()"));
        weeklySalary.createContractor(bob, 1000e18);
    }

    function test_revertContractorIsAddressZero(uint256 amount) public {
        vm.expectRevert(abi.encodeWithSignature("InvalidContractorAddress()"));
        weeklySalary.createContractor(address(0), amount);
    }

    function test_deleteContractor(uint256 amount) public {
        vm.assume(amount != 0);
        address bob = makeAddr("bob");
        vm.prank(weeklySalary.owner());
        weeklySalary.createContractor(bob, amount);

        vm.prank(weeklySalary.owner());
        weeklySalary.deleteContractor(bob);

        (uint256 weeklySalaryAmount, uint256 lastWithdrawal) = weeklySalary.contractors(bob);
        assertEq(weeklySalaryAmount, 0);
        assertEq(lastWithdrawal, 0);
    }

    function test_deleteContractor_revertsIfContractorDoesNotExist(uint256 amount) public {
        vm.assume(amount != 0);
        vm.prank(weeklySalary.owner());
        vm.expectRevert(abi.encodeWithSignature("InvalidContractorAddress()"));
        weeklySalary.deleteContractor(address(1337));
    }
    
    function test_deleteContractor_notOwnerCannotDeleteContractor(address hacker) public {
        vm.assume(hacker != weeklySalary.owner());
        vm.prank(hacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", hacker));
        weeklySalary.deleteContractor(address(1337));
    }

    function test_withdraw_before_one_week(uint256 amount, address contractor) public {
        vm.assume(amount != 0);
        vm.assume(uint160(contractor) > 1000 && contractor.code.length == 0);
        vm.prank(weeklySalary.owner());
        weeklySalary.createContractor(contractor, amount);

        vm.warp(block.timestamp + 7 days - 1 seconds);
        vm.prank(contractor);
        weeklySalary.withdraw();

        assertEq(RareSkillsToken(address(rareSkillsToken)).balanceOf(contractor), 0);
    }

    function test_withdraw_after_one_week(uint256 amount, address contractor) public {
        vm.assume(amount != 0);
        vm.assume(uint160(contractor) > 1000 && contractor.code.length == 0);
        vm.prank(weeklySalary.owner());
        weeklySalary.createContractor(contractor, amount);
        rareSkillsToken.mint(address(weeklySalary), amount);

        vm.warp(block.timestamp + 7 days);
        vm.prank(contractor);
        weeklySalary.withdraw();

        assertEq(RareSkillsToken(address(rareSkillsToken)).balanceOf(contractor), amount);
    }

    function test_withdraw_after_one_week_track_prior_withdrawal(uint24 _amount, address contractor) public {
        uint256 amount = uint256(_amount);
        vm.assume(amount != 0);
        vm.assume(uint160(contractor) > 1000 && contractor.code.length == 0);
        vm.prank(weeklySalary.owner());
        weeklySalary.createContractor(contractor, amount);
        rareSkillsToken.mint(address(weeklySalary), amount * 2);

        skip(7 days);
        vm.prank(contractor);
        weeklySalary.withdraw();

        assertEq(RareSkillsToken(address(rareSkillsToken)).balanceOf(contractor), amount);

        skip(6 days);
        vm.prank(contractor);
        weeklySalary.withdraw();

        // shouldn't get more money before the next week
        assertEq(RareSkillsToken(address(rareSkillsToken)).balanceOf(contractor), amount);
    }

    function test_withdraw_after_two_weeks(uint24 _amount, address contractor) public {
        // uint24 is to bound the size, but uint24 * 2 can overflow
        // because Solidity does not implicitly upcast
        uint256 amount = uint256(_amount);
        vm.assume(amount != 0);
        vm.assume(uint160(contractor) > 1000 && contractor.code.length == 0);
        vm.prank(weeklySalary.owner());
        weeklySalary.createContractor(contractor, amount);
        rareSkillsToken.mint(address(weeklySalary), amount * 2);

        vm.warp(block.timestamp + 14 days);
        vm.prank(contractor);
        weeklySalary.withdraw();

        assertEq(RareSkillsToken(address(rareSkillsToken)).balanceOf(contractor), 2 * amount);
    }
    
}