// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ReverseDutchAuction, IERC20} from "../../src/ReverseDutchAuction.sol";

/// @dev This handler will abstract the transferFrom approval away as well as
/// track the amounts in ghost variables
contract RDA_Handler is Test {
    ReverseDutchAuction target;

    uint256 public ghost_balanceBuyerAcceptedTokenBefore;
    uint256 public ghost_balanceBuyerTokenAlotedBefore;
    uint256 public ghost_balanceSellerAcceptedTokenBefore;
    uint256 public ghost_balanceSellerTokenAlotedBefore;
    uint256 public ghost_balanceContractAcceptedTokenBefore;
    uint256 public ghost_balanceContractTokenAlotedBefore;

    uint256 public ghost_balanceBuyerAcceptedTokenAfter;
    uint256 public ghost_balanceBuyerTokenAlotedAfter;
    uint256 public ghost_balanceSellerAcceptedTokenAfter;
    uint256 public ghost_balanceSellerTokenAlotedAfter;
    uint256 public ghost_balanceContractAcceptedTokenAfter;
    uint256 public ghost_balanceContractTokenAlotedAfter;

    uint256 public ghost_priceUsed;

    constructor(ReverseDutchAuction _target) {
        target = _target;
    }

    function handler_bid(uint256 priceOffered, uint256 timeElapsed) public trackBalances {
        // Constrain the current timestamp as valid for the auction
        timeElapsed = bound(timeElapsed, 0, target.AUCTION_DURATION());

        // Setup:
        vm.warp(block.timestamp + timeElapsed);

        IERC20 acceptedToken = target.ACCEPTED_TOKEN();
        IERC20 tokenAloted = target.TOKEN_ALOTED();
        address seller = target.SELLER();

        deal(address(acceptedToken), msg.sender, priceOffered * target.AMOUNT_SOLD(), true);

        vm.prank(msg.sender);
        acceptedToken.approve(address(target), priceOffered);

        // Ghost variables before
        ghost_balanceBuyerAcceptedTokenBefore = acceptedToken.balanceOf(msg.sender);
        ghost_balanceBuyerTokenAlotedBefore = tokenAloted.balanceOf(msg.sender);
        ghost_balanceSellerAcceptedTokenBefore = acceptedToken.balanceOf(seller);
        ghost_balanceSellerTokenAlotedBefore = tokenAloted.balanceOf(seller);
        ghost_balanceContractAcceptedTokenBefore = acceptedToken.balanceOf(address(target));
        ghost_balanceContractTokenAlotedBefore = tokenAloted.balanceOf(address(target));

        // Action:
        vm.prank(msg.sender);
        target.bid(priceOffered);

        // Ghost variables after
        ghost_balanceBuyerAcceptedTokenAfter = acceptedToken.balanceOf(msg.sender);
        ghost_balanceBuyerTokenAlotedAfter = tokenAloted.balanceOf(msg.sender);
        ghost_balanceSellerAcceptedTokenAfter = acceptedToken.balanceOf(seller);
        ghost_balanceSellerTokenAlotedAfter = tokenAloted.balanceOf(seller);
        ghost_balanceContractAcceptedTokenAfter = acceptedToken.balanceOf(address(target));
        ghost_balanceContractTokenAlotedAfter = tokenAloted.balanceOf(address(target));

        // Actual price used
        ghost_priceUsed = priceOffered;
    }

    modifier trackBalances() {
        _;
    }
}
