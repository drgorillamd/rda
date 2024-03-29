// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ReverseDutchAuction, IERC20} from "../../src/ReverseDutchAuction.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";

contract RDA_Bid_unitTests is Test {
    event AuctionSettled(
        address indexed buyer,
        IERC20 indexed acceptedToken,
        IERC20 indexed tokenAloted,
        uint256 amountAlotedSold,
        uint256 amountAcceptedReceived
    );

    IERC20 acceptedToken;
    IERC20 tokenAloted;
    uint256 initialPrice;
    uint256 minPrice;
    uint256 duration;
    uint256 amountSold;
    address seller;

    ReverseDutchAuction target;

    function setUp() public {
        // Dummy values
        acceptedToken = IERC20(address(new MockERC20()));
        tokenAloted = IERC20(address(new MockERC20()));
        initialPrice = 100;
        minPrice = 1;
        duration = 10;
        amountSold = 200;
        seller = makeAddr("seller");

        // initial token transfer to the contract
        address nextDeploymentAddress = vm.computeCreateAddress(address(this), vm.getNonce(address(this)));

        deal(address(tokenAloted), address(this), amountSold, true);

        tokenAloted.approve(nextDeploymentAddress, amountSold);

        // deploy the contract
        target = new ReverseDutchAuction({
            _acceptedToken: acceptedToken,
            _tokenAloted: tokenAloted,
            _initialPrice: initialPrice,
            _minPrice: minPrice,
            _duration: duration,
            _amountSold: amountSold,
            _seller: seller
        });
    }

    modifier whenTheCurrentPriceIsAboveTheFloorPrice() {
        _;
    }

    function test_WhenPassingAPriceHigherThanTheCurrentPrice(uint256 _bidPrice, uint256 _auctionProgression)
        external
        whenTheCurrentPriceIsAboveTheFloorPrice
    {
        _auctionProgression = bound(_auctionProgression, 0, duration);
        _bidPrice = bound(_bidPrice, minPrice, initialPrice - initialPrice * _auctionProgression / duration);

        deal(address(acceptedToken), address(this), _bidPrice * amountSold, true);

        // it should transfer the accepted token to the seller
        
        // it should transfer the token being sold to the bidder

        // it should emit an AuctionSettled event
        vm.expectEmit(true, true, true, true);
        emit AuctionSettled(msg.sender, acceptedToken, tokenAloted, amountSold, _bidPrice * amountSold);

        // it should settle the auction
        target.bid(_bidPrice);
    }

    function test_RevertWhen_PassingAPriceLowerThanTheCurrentPrice() external whenTheCurrentPriceIsAboveTheFloorPrice {
        // it should revert
    }

    modifier whenTheCurrentPriceIsLessThanTheFloorPrice() {
        _;
    }

    function test_WhenPassingAPriceAboveTheFloorPrice() external whenTheCurrentPriceIsLessThanTheFloorPrice {
        // it should settle the auction on the floor price
    }

    function test_RevertWhen_PassingAPriceLessThanTheFloorPrice() external whenTheCurrentPriceIsLessThanTheFloorPrice {
        // it should revert
    }

    function test_RevertWhen_TryingToBidOnASettledAuction() external {
        // it should revert
    }

    function test_RevertWhen_TryingToBidOnAnAuctionThatHasExpired() external {
        // it should revert
    }

    function mockExpectCall(address _target, bytes memory callData, bytes memory returnedData) internal {
        vm.mockCall(_target, callData, returnedData);
        vm.expectCall(_target, callData);
    }
}
