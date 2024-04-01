// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console, stdStorage, StdStorage} from "forge-std/Test.sol";
import {Utils} from "../lib/utils.sol";
import {ReverseDutchAuction, IERC20} from "../../src/ReverseDutchAuction.sol";
import {MockERC20Mintable} from "../lib/MockERC20Mintable.sol";

contract RDA_Bid_unitTests is Test, Utils {
    using stdStorage for StdStorage;

    event AuctionSettled(
        address indexed buyer,
        IERC20 indexed acceptedToken,
        IERC20 indexed tokenAloted,
        uint256 amountAlotedSold,
        uint256 amountAcceptedReceived
    );

    // Auction parameters
    IERC20 acceptedToken;
    IERC20 tokenAloted;
    uint256 initialPrice;
    uint256 minPrice;
    uint256 duration;
    uint256 amountSold;
    address seller;

    // Contract under test
    ReverseDutchAuction target;

    // Fuzz variables, for the modifiers
    uint256 auctionProgression; // number of seconds since the auction started

    function setUp() public {
        // Dummy values
        acceptedToken = IERC20(address(new MockERC20Mintable()));
        vm.label(address(acceptedToken), "acceptedToken");

        // We need actual erc20's to satisfy the bid's invariants (no mock with different
        // results, like in smock for instance)
        tokenAloted = IERC20(address(new MockERC20Mintable()));
        vm.label(address(tokenAloted), "tokenAloted");

        initialPrice = 2 ether;
        minPrice = 1 ether;
        duration = 10 days;
        amountSold = 200 ether;
        seller = makeAddr("seller");

        // initial token transfer to the contract
        address nextDeploymentAddress = vm.computeCreateAddress(address(this), vm.getNonce(address(this)));

        deal(address(tokenAloted), address(this), amountSold, true);

        tokenAloted.approve(nextDeploymentAddress, amountSold);

        // deploy the contract
        target = new ReverseDutchAuction({
            acceptedToken: acceptedToken,
            tokenAloted: tokenAloted,
            initialPrice: initialPrice,
            minPrice: minPrice,
            duration: duration,
            amountSold: amountSold,
            seller: seller
        });
    }

    modifier whenTheCurrentPriceIsAboveTheFloorPrice(uint256 _progressionFuzzSeed) {
        // the duration after which the floor price is reached
        uint256 floorPriceReachedAfterSeconds = duration * (initialPrice - minPrice) / initialPrice;

        auctionProgression = bound(_progressionFuzzSeed, 0, floorPriceReachedAfterSeconds);
        _;
    }

    function test_WhenPassingAPriceHigherThanTheCurrentPrice(uint256 _bidPrice, uint256 _progressionFuzzSeed)
        external
        whenTheCurrentPriceIsAboveTheFloorPrice(_progressionFuzzSeed)
    {
        // current price is between the minimum accepted one, until initialPrice * 100 (to avoid overflowing on the price calculation)
        _bidPrice = bound(_bidPrice, initialPrice - initialPrice * auctionProgression / duration, initialPrice * 100);

        deal(address(acceptedToken), address(this), _bidPrice * amountSold, true);
        acceptedToken.approve(address(target), _bidPrice * amountSold);

        vm.warp(block.timestamp + auctionProgression);

        // it should emit an AuctionSettled event
        vm.expectEmit(true, true, true, true);
        emit AuctionSettled(address(this), acceptedToken, tokenAloted, amountSold, _bidPrice * amountSold);

        // Test: bid
        target.bid(_bidPrice);

        // it should transfer the accepted token to the seller
        assertEq(acceptedToken.balanceOf(seller), _bidPrice * amountSold);

        // it should transfer the token being sold to the bidder
        assertEq(tokenAloted.balanceOf(address(this)), amountSold);

        // it should settle the auction
        assertTrue(target.auctionSettled());
    }

    function test_RevertWhen_PassingAPriceLowerThanTheCurrentPrice(uint256 _bidPrice, uint256 _auctionProgression)
        external
        whenTheCurrentPriceIsAboveTheFloorPrice(_auctionProgression)
    {
        // current price is between the minimum accepted one, until uint248.max (to avoid overflowing on the price calculation)
        _bidPrice = bound(_bidPrice, 0, initialPrice - initialPrice * auctionProgression / duration - 1);

        deal(address(acceptedToken), address(this), _bidPrice * amountSold, true);
        acceptedToken.approve(address(target), _bidPrice * amountSold);

        vm.warp(block.timestamp + auctionProgression);

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Bid_BidPriceTooLow.selector);

        // Test: bid
        target.bid(_bidPrice);
    }

    modifier whenTheCurrentPriceIsLessThanTheFloorPrice(uint256 _progressionFuzzSeed) {
        // the duration after which the floor price is reached
        uint256 floorPriceReachedAfterSeconds = duration * (initialPrice - minPrice) / initialPrice;

        auctionProgression = bound(_progressionFuzzSeed, floorPriceReachedAfterSeconds, duration);
        _;
    }

    function test_WhenPassingAPriceAboveTheFloorPrice(uint256 _bidPrice, uint256 _progressionFuzzSeed)
        external
        whenTheCurrentPriceIsLessThanTheFloorPrice(_progressionFuzzSeed)
    {
        // current price is at least the minimum one
        _bidPrice = bound(_bidPrice, minPrice, initialPrice * 100);

        deal(address(acceptedToken), address(this), _bidPrice * amountSold, true);
        acceptedToken.approve(address(target), _bidPrice * amountSold);

        vm.warp(block.timestamp + auctionProgression);

        // it should emit an AuctionSettled event
        vm.expectEmit(true, true, true, true);
        emit AuctionSettled(address(this), acceptedToken, tokenAloted, amountSold, _bidPrice * amountSold);

        // Test: bid
        target.bid(_bidPrice);

        // it should settle the auction on the floor price
        assertTrue(target.auctionSettled());

        // it should transfer the accepted token to the seller
        assertEq(acceptedToken.balanceOf(seller), _bidPrice * amountSold);

        // it should transfer the token being sold to the bidder
        assertEq(tokenAloted.balanceOf(address(this)), amountSold);
    }

    function test_RevertWhen_PassingAPriceLessThanTheFloorPrice(uint256 _bidPrice, uint256 _progressionFuzzSeed)
        external
        whenTheCurrentPriceIsLessThanTheFloorPrice(_progressionFuzzSeed)
    {
        // current price is bellow the minimum price
        _bidPrice = bound(_bidPrice, 0, minPrice - 1);

        deal(address(acceptedToken), address(this), _bidPrice * amountSold, true);
        acceptedToken.approve(address(target), _bidPrice * amountSold);

        vm.warp(block.timestamp + auctionProgression);

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Bid_BidPriceTooLow.selector);

        // Test: bid
        target.bid(_bidPrice);
    }

    function test_RevertWhen_TryingToBidOnASettledAuction() external {
        // it should revert
        stdstore.target(address(target)).sig("auctionSettled()").checked_write(true);

        vm.expectRevert(ReverseDutchAuction.RDA_Bid_AuctionSettled.selector);
        target.bid(initialPrice);
    }

    function test_RevertWhen_TryingToBidOnAnAuctionThatHasExpired(uint256 _auctionProgression) external {
        // fuzz until reaching the floor price, as we test when current > min
        _auctionProgression = bound(_auctionProgression, duration + 1, type(uint128).max);

        uint256 _bidPrice = initialPrice + 1;

        deal(address(acceptedToken), address(this), _bidPrice * amountSold, true);
        acceptedToken.approve(address(target), _bidPrice * amountSold);

        vm.warp(block.timestamp + _auctionProgression);

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Bid_AuctionExpired.selector);

        // Test: bid
        target.bid(_bidPrice);
    }
}
