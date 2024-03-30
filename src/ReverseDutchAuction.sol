// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title  Reverse Dutch Auction
/// @notice A reverse dutch auction contract that allows to sell a fixed amount of a set token
/// @dev    This contract is meant as a single-use contract (ie for a single auction), as most
///         of the parameters are then immutables.
///         Price is the amount of acceptedToken per tokenAloted.
contract ReverseDutchAuction {
    /////////////////////////////////////////////////////////////////////
    //                             Events                              //
    /////////////////////////////////////////////////////////////////////

    event AuctionCreated(
        address indexed seller, IERC20 indexed acceptedToken, IERC20 indexed tokenAloted, uint256 amountAlotedSold
    );
    event AuctionSettled(
        address indexed buyer,
        IERC20 indexed acceptedToken,
        IERC20 indexed tokenAloted,
        uint256 amountAlotedSold,
        uint256 amountAcceptedReceived
    );

    /////////////////////////////////////////////////////////////////////
    //                             Errors                              //
    /////////////////////////////////////////////////////////////////////

    error RDA_Constructor_WrongTokenIn();
    error RDA_Constructor_WrongTokenOut();
    error RDA_Constructor_InitialPriceZero();
    error RDA_Constructor_DurationZero();
    error RDA_Constructor_AmountSoldZero();
    error RDA_Constructor_SellerZero();

    error RDA_Bid_BidPriceTooLow();
    error RDA_Bid_AuctionExpired();
    error RDA_Bid_AuctionSettled();

    /////////////////////////////////////////////////////////////////////
    //                        Public immutables                        //
    /////////////////////////////////////////////////////////////////////

    IERC20 public immutable ACCEPTED_TOKEN;
    IERC20 public immutable TOKEN_ALOTED;

    uint256 public immutable INITIAL_PRICE;
    uint256 public immutable MIN_PRICE;
    uint256 public immutable AMOUNT_SOLD;
    uint256 public immutable AUCTION_STARTING_TIMESTAMP;
    uint256 public immutable AUCTION_DURATION;

    address public immutable SELLER;

    /////////////////////////////////////////////////////////////////////
    //                     Public state variables                      //
    /////////////////////////////////////////////////////////////////////

    bool public auctionSettled;

    /////////////////////////////////////////////////////////////////////
    //                           Constructor                           //
    /////////////////////////////////////////////////////////////////////

    constructor(
        IERC20 _acceptedToken,
        IERC20 _tokenAloted,
        uint256 _initialPrice,
        uint256 _minPrice,
        uint256 _duration,
        uint256 _amountSold,
        address _seller
    ) {
        // Checks/function requirements
        if (address(_acceptedToken) == address(0)) revert RDA_Constructor_WrongTokenIn();
        if (address(_tokenAloted) == address(0)) revert RDA_Constructor_WrongTokenOut();
        if (_initialPrice == 0) revert RDA_Constructor_InitialPriceZero();
        if (_duration == 0) revert RDA_Constructor_DurationZero();
        if (_amountSold == 0) revert RDA_Constructor_AmountSoldZero();
        if (_seller == address(0)) revert RDA_Constructor_SellerZero();

        // Effects
        ACCEPTED_TOKEN = _acceptedToken;
        TOKEN_ALOTED = _tokenAloted;
        INITIAL_PRICE = _initialPrice;
        MIN_PRICE = _minPrice;
        AMOUNT_SOLD = _amountSold;
        SELLER = _seller;
        AUCTION_STARTING_TIMESTAMP = block.timestamp;
        AUCTION_DURATION = _duration;

        // Interactions
        _tokenAloted.transferFrom(msg.sender, address(this), _amountSold);
        emit AuctionCreated(_seller, _acceptedToken, _tokenAloted, _amountSold);
    }

    /////////////////////////////////////////////////////////////////////
    //                        Public functions                         //
    /////////////////////////////////////////////////////////////////////

    /// @notice Bid on the current reverse dutch auction
    /// @dev The bid should be greater than MAX(current price; floor price).
    ///      The auction should not have expired.
    ///      The auction should not have been already settled.
    ///      The buyer and the seller balances are constraint to be increasing/decreasing
    ///      from the correct amount (the contracts balance isn't contrained to be 0 after settlement, as
    ///      it would allow griefing by sending 1 extra token to the contract).
    /// @param _proposedPrice The price the buyer is willing to pay for the tokens
    function bid(uint256 _proposedPrice) public {
        // Function Requirements
        if (block.timestamp > AUCTION_STARTING_TIMESTAMP + AUCTION_DURATION) revert RDA_Bid_AuctionExpired();
        if (auctionSettled) revert RDA_Bid_AuctionSettled();

        // Effects
        uint256 balanceBuyerBefore = TOKEN_ALOTED.balanceOf(msg.sender);
        uint256 balanceSellerBefore = ACCEPTED_TOKEN.balanceOf(SELLER);

        uint256 currentPrice =
            INITIAL_PRICE - INITIAL_PRICE * (block.timestamp - AUCTION_STARTING_TIMESTAMP) / AUCTION_DURATION;

        // Take the floor price into account
        currentPrice = currentPrice < MIN_PRICE ? MIN_PRICE : currentPrice;

        if (_proposedPrice < currentPrice) revert RDA_Bid_BidPriceTooLow();

        auctionSettled = true;

        // Interactons
        ACCEPTED_TOKEN.transferFrom(msg.sender, SELLER, AMOUNT_SOLD * _proposedPrice);
        TOKEN_ALOTED.transfer(msg.sender, AMOUNT_SOLD);

        emit AuctionSettled(msg.sender, ACCEPTED_TOKEN, TOKEN_ALOTED, AMOUNT_SOLD, AMOUNT_SOLD * _proposedPrice);

        // Invariants: no token "lost" along the way
        uint256 balanceBuyerAfter = TOKEN_ALOTED.balanceOf(msg.sender);
        assert(balanceBuyerAfter == balanceBuyerBefore + AMOUNT_SOLD);

        uint256 balanceSellerAfter = ACCEPTED_TOKEN.balanceOf(SELLER);
        assert(balanceSellerAfter == balanceSellerBefore + AMOUNT_SOLD * _proposedPrice);
    }
}
