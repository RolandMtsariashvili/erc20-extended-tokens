// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// If someone wants to sell a token, they create a dutch auction using the linear dutch auction factory.
// In a single transaction, the factory creates the auction and the token is transferred from the user to the auction.
contract LinearDutchAuctionFactory {
    using SafeERC20 for IERC20;
    event AuctionCreated(address indexed auction, address indexed token, uint256 startingPriceEther, uint256 startTime, uint256 duration, uint256 amount, address seller);

    function createAuction(
        IERC20 _token,
        uint256 _startingPriceEther,
        uint256 _startTime,
        uint256 _duration,
        uint256 _amount,
        address _seller
    ) external returns (address) {
        require(_duration > 0);
        require(_startTime >= block.timestamp);
        require(_startingPriceEther > 0);
        require(_seller != address(0));

        LinearDutchAuction auction =  new LinearDutchAuction(_token, _startingPriceEther, _startTime, _duration, _seller);
        address addressAuction = address(auction);
    
        _token.safeTransferFrom(msg.sender, addressAuction, _amount);

        emit AuctionCreated(addressAuction, address(_token), _startingPriceEther, _startTime, _duration, _amount, _seller);
        return address(addressAuction);
    }
}

// The auction is a contract that sells the token at a decreasing price until the duration is over.
// The price starts at `startingPriceEther` and decreases linearly to 0 over the `duration`.
// Someone can buy the token at the current price by sending ether to the auction.
// The auction will try to refund the user if they send too much ether.
// The contract directly sends the Ether to the `seller` and does not hold any ether.
// If the price goes to zero, anyone can claim the tokens by calling the contract with msg.value = 0
contract LinearDutchAuction {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint256 public immutable startingPriceEther;
    uint256 public immutable startTime;
    uint256 public immutable durationSeconds;
    address public immutable seller;

    bool private isPurchased;

    error AuctionNotStarted();
    error MsgValueInsufficient();
    error SendEtherToSellerFailed();

    /*
     * @notice Constructor
     * @param _token The token to sell
     * @param _startingPriceEther The starting price of the token in Ether
     * @param _startTime The start time of the auction.
     * @param _duration The duration of the auction. In seconds
     * @param _seller The address of the seller
     */
    constructor(
        IERC20 _token,
        uint256 _startingPriceEther,
        uint256 _startTime,
        uint256 _durationSeconds,
        address _seller
    ) {
        token = _token;
        startingPriceEther = _startingPriceEther;
        startTime =_startTime;
        durationSeconds = _durationSeconds;
        seller = _seller;
    }

    modifier NotPurchasedOnly {
        require(!isPurchased);
        _;
    }

    /*
     * @notice Get the current price of the token
     * @dev Returns 0 if the auction has ended
     * @revert if the auction has not started yet
     * @revert if someone already purchased the token
     * @return the current price of the token in Ether
     */ 
    function calculateCurrentPrice() internal view NotPurchasedOnly returns (uint256)  {
        uint passedTime = block.timestamp - startTime;

        uint amountToPay = startingPriceEther - startingPriceEther * passedTime / durationSeconds;
        return amountToPay;
    }

    function currentPrice() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if (currentTime < startTime) revert AuctionNotStarted();
        if (currentTime > startTime + durationSeconds) return 0;

        return calculateCurrentPrice();
    }

    /*
     * @notice Buy tokens at the current price
     * @revert if the auction has not started yet
     * @revert if the auction has ended
     * @revert if the user sends too little ether for the current price
     * @revert if sending Ether to the seller fails
     * @dev Will try to refund the user if they send too much ether. If the refund reverts, the transaction still succeeds.
     */
    receive() external payable NotPurchasedOnly {
        uint256 currentTime = block.timestamp;


        if (currentTime < startTime) revert AuctionNotStarted();
        if (currentTime > startTime + durationSeconds) revert();

        uint256 calculatedPrice = calculateCurrentPrice();
        
        require(msg.value >= calculatedPrice);
        // Will revert if not enough balance
        uint256 remainder = msg.value - calculatedPrice;

        uint balance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, balance);

        isPurchased = true;

        (bool success, ) = payable(seller).call{value: calculatedPrice}("");
        require(success);

        if (remainder > 0) {
            payable(msg.sender).call{ value: remainder }("");
        }

    }
}
