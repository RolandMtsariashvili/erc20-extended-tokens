// SPDX-License-Identifier: (c) RareSkills
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RareToken is ERC20 {
    constructor() ERC20("RareToken", "RT") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract CrowdfundingTest is Test {
    Crowdfunding public crowdfunding;
    RareToken public token;
    address public beneficiary = address(0xBEEF);
    address public contributor = address(0xCAFE);
    uint256 public fundingGoal = 1000 ether;
    uint256 public deadline;

    // Declare the events to be tested
    event Contribution(address indexed contributor, uint256 amount);
    event CancelContribution(address indexed contributor, uint256 amount);
    event Withdrawal(address indexed beneficiary, uint256 amount);

    function setUp() public {
        token = new RareToken();
        deadline = block.timestamp + 7 days;
        crowdfunding = new Crowdfunding(address(token), beneficiary, fundingGoal, deadline);

        token.mint(contributor, 5000 ether);
        vm.startPrank(contributor);
        token.approve(address(crowdfunding), 5000 ether);
        vm.stopPrank();
    }

    function testConstructor() public {
        assertEq(address(crowdfunding.token()), address(token));
        assertEq(crowdfunding.beneficiary(), beneficiary);
        assertEq(crowdfunding.fundingGoal(), fundingGoal);
        assertEq(crowdfunding.deadline(), deadline);
    }

    function testConstructorRevertsWithZeroTokenAddress() public {
        vm.expectRevert("Token address cannot be 0");
        new Crowdfunding(address(0), beneficiary, fundingGoal, deadline);
    }

    function testConstructorRevertsWithZeroBeneficiaryAddress() public {
        vm.expectRevert("Beneficiary address cannot be 0");
        new Crowdfunding(address(token), address(0), fundingGoal, deadline);
    }

    function testConstructorRevertsWithZeroFundingGoal() public {
        vm.expectRevert("Funding goal must be greater than 0");
        new Crowdfunding(address(token), beneficiary, 0, deadline);
    }

    function testConstructorRevertsWithPastDeadline() public {
        vm.expectRevert("Deadline must be in the future");
        new Crowdfunding(address(token), beneficiary, fundingGoal, block.timestamp - 1);
    }

    function testContribute() public {
        vm.startPrank(contributor);
        crowdfunding.contribute(500 ether);
        vm.stopPrank();

        assertEq(crowdfunding.contributions(contributor), 500 ether);
        assertEq(token.balanceOf(address(crowdfunding)), 500 ether);
    }

    function testCannotContributeAfterDeadline() public {
        vm.warp(deadline + 1);
        vm.startPrank(contributor);
        vm.expectRevert("Contribution period over");
        crowdfunding.contribute(500 ether);
        vm.stopPrank();
    }

    function testCancelContributionBeforeDeadline() public {
        vm.startPrank(contributor);
        crowdfunding.contribute(500 ether);
        crowdfunding.cancelContribution();
        vm.stopPrank();

        assertEq(crowdfunding.contributions(contributor), 0 ether); // Note: contributions mapping isn't reset in original contract
    }

    function testCannotCancelContributionAfterGoalReached() public {
        vm.startPrank(contributor);
        crowdfunding.contribute(fundingGoal);
        vm.stopPrank();

        vm.warp(deadline + 1);

        vm.startPrank(contributor);
        vm.expectRevert("Cannot cancel after goal reached");
        crowdfunding.cancelContribution();
        vm.stopPrank();
    }

    function testWithdrawAfterGoalReached() public {
        vm.startPrank(contributor);
        crowdfunding.contribute(fundingGoal);
        vm.stopPrank();

        vm.warp(deadline + 1);

        uint256 beneficiaryBalanceBefore = token.balanceOf(beneficiary);

        vm.prank(beneficiary);
        crowdfunding.withdraw();

        assertEq(token.balanceOf(beneficiary), beneficiaryBalanceBefore + fundingGoal);
        assertEq(token.balanceOf(address(crowdfunding)), 0);
    }

    function testCannotWithdrawBeforeDeadline() public {
        vm.startPrank(contributor);
        crowdfunding.contribute(fundingGoal);
        vm.stopPrank();

        vm.prank(beneficiary);
        vm.expectRevert("Funding period not over");
        crowdfunding.withdraw();
    }

    function testCannotWithdrawIfGoalNotReached() public {
        vm.startPrank(contributor);
        crowdfunding.contribute(fundingGoal - 1 ether);
        vm.stopPrank();

        vm.warp(deadline + 1);

        vm.prank(beneficiary);
        vm.expectRevert("Funding goal not reached");
        crowdfunding.withdraw();
    }

    function testOnlyBeneficiaryCanWithdraw() public {
        vm.startPrank(contributor);
        crowdfunding.contribute(fundingGoal);
        vm.stopPrank();

        vm.warp(deadline + 1);

        vm.prank(contributor);
        vm.expectRevert("Only beneficiary can withdraw");
        crowdfunding.withdraw();
    }

    function testContributionEventEmitted() public {
        vm.startPrank(contributor);
        vm.expectEmit();
        emit Contribution(contributor, 500 ether);
        crowdfunding.contribute(500 ether);
        vm.stopPrank();
    }

    function testCancelContributionEventEmitted() public {
        vm.startPrank(contributor);
        crowdfunding.contribute(500 ether);
        vm.expectEmit();
        emit CancelContribution(contributor, 500 ether);
        crowdfunding.cancelContribution();
        vm.stopPrank();
    }

    function testWithdrawalEventEmitted() public {
        vm.startPrank(contributor);
        crowdfunding.contribute(fundingGoal);
        vm.stopPrank();

        vm.warp(deadline + 1);

        uint256 beneficiaryBalanceBefore = token.balanceOf(beneficiary);
        uint256 contractBalance = token.balanceOf(address(crowdfunding));

        vm.prank(beneficiary);
        vm.expectEmit();
        emit Withdrawal(beneficiary, contractBalance);
        crowdfunding.withdraw();

    }
}