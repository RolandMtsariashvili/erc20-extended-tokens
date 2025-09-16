// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// In the Uniswap V2 style deposit, the sender deposits
// the ERC-20 token to the contract, and then calls deposit
// this needs to be done in a single transaction, so it 
// is intended for integration with other smart contracts

interface IPool {
    function balances(address depositor) external view returns (uint256);
    function deposit() external; // there is no "amount" parameter
}

contract Depositor {
    IERC20 public immutable token;
    using SafeERC20 for IERC20;

    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function sendTokens(address pool, uint256 amount) external {
        token.safeTransfer(pool, amount);
        IPool(pool).deposit();
    }
}


// modify this contract to support the functionality
// described above
contract Pool is IPool {
    IERC20 public immutable token;
    uint256 public totalDeposits;

    event Deposit(address indexed depositor, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    mapping(address depositor => uint256) public balances;

    function deposit() external {
        // credit depositor with the amount that they sent to `balances` 
        uint256 depositedNow = token.balanceOf(address(this));
        uint delta =depositedNow - totalDeposits;

        balances[msg.sender] += delta;
        totalDeposits += delta;

        emit Deposit(msg.sender, delta);
    }
}
