// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ReverseDutchAuction, IERC20} from "../../src/ReverseDutchAuction.sol";
import {MockERC20Mintable} from "../lib/MockERC20Mintable.sol";
import {IWETH9} from "./../lib/IWETH9.sol";
import {RDA_Handler} from "./RDA_handler.sol";

/// @notice The invariants which should hold are:
/// - the buyer's balance of aloted token should increase by the amount of tokens bought
/// - the seller's balance of accepted token should increase by the amount of tokens bought * the bid price
/// - the buyer's balance of accepted token should decrease by the amount of tokens bought * the bid price
/// - the bid >= MAX(minPrice, currentPrice)
/// the first 2 are constraint in the contract itself

contract RDA_Invariant is Test {
    IERC20 acceptedToken = IERC20(address(new MockERC20Mintable()));
    IERC20 tokenAloted = IERC20(address(new MockERC20Mintable()));

    uint256 initialPrice = 1 ether;
    uint256 minPrice = 0.001 ether;
    uint256 duration = 10 days;
    uint256 amountSold = 200 ether;

    ReverseDutchAuction target;
    RDA_Handler handler;

    function setUp() public {

        address seller = makeAddr("seller");

        deal(address(tokenAloted), seller, amountSold, true);

        // deploy the contract
        vm.startPrank(seller);

        address nextDeploymentAddress = vm.computeCreateAddress(seller, vm.getNonce(seller));

        tokenAloted.approve(nextDeploymentAddress, amountSold);

        target = new ReverseDutchAuction({
            _acceptedToken: acceptedToken,
            _tokenAloted: tokenAloted,
            _initialPrice: initialPrice,
            _minPrice: minPrice,
            _duration: duration,
            _amountSold: amountSold,
            _seller: seller
        });

        vm.stopPrank();

        handler = new RDA_Handler(target);

        targetContract(address(handler));
    }

    function invariant_1_BuyerAlotedBalanceIncreases() public {
        assertEq(handler.ghost_balanceBuyerTokenAlotedAfter(), handler.ghost_balanceBuyerTokenAlotedBefore() + target.AMOUNT_SOLD());
    }

    function invariant_2_SellerAcceptedBalanceIncreases() public {
        assertEq(handler.ghost_balanceSellerAcceptedTokenAfter(), handler.ghost_balanceSellerAcceptedTokenBefore() + handler.ghost_priceUsed() * target.AMOUNT_SOLD());
    }

    function invariant_3_BuyerAcceptedBalanceDecreases() public {
        assertEq(handler.ghost_balanceBuyerAcceptedTokenAfter(), handler.ghost_balanceBuyerAcceptedTokenBefore() - handler.ghost_priceUsed() * target.AMOUNT_SOLD());

    }

    function invariant_4_BidPriceFollowsPricingFunctionAndFloor() public {
        assertGe(handler.ghost_priceUsed(), target.MIN_PRICE());
    }
}
