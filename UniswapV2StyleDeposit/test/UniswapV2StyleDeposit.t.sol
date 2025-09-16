// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Pool} from "../src/UniswapV2StyleDeposit.sol";
import {Depositor} from "../src/UniswapV2StyleDeposit.sol";

contract RareSkillsToken is ERC20 {
    constructor() ERC20("RareSkills", "RST") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract UniswapV2StyleDepositTest is Test {
    Pool public pool;
    Depositor public depositor;
    RareSkillsToken public token;
    function setUp() public {
        token = new RareSkillsToken();
        pool = new Pool(address(token));
        depositor = new Depositor(address(token));
    }

    function test_deposit() public {
        token.mint(address(depositor), 100e18);
        depositor.sendTokens(address(pool), 100e18);
        assertEq(pool.balances(address(depositor)), 100e18);
    }

    function test_deposit_event() public {
        token.mint(address(depositor), 100e18);
        vm.expectEmit();
        emit Pool.Deposit(address(depositor), 100e18);
        depositor.sendTokens(address(pool), 100e18);
    }

    function test_send_no_deposit_call() public {
        token.mint(address(this), 100e18);
        pool.deposit();
        assertEq(pool.balances(address(this)), 0);
    }
}
    