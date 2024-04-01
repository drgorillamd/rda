// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Utils} from "../lib/utils.sol";

import {ReverseDutchAuction, IERC20} from "../../src/ReverseDutchAuction.sol";

contract RDA_Constructor_unitTests is Test, Utils {
    // Events to test
    event AuctionCreated(
        address indexed seller, IERC20 indexed acceptedToken, IERC20 indexed tokenAloted, uint256 amountAlotedSold
    );

    function test_WhenPassingCorrectArguments(
        IERC20 acceptedToken,
        IERC20 tokenAloted,
        uint256 initialPrice,
        uint256 minPrice,
        uint256 duration,
        uint256 amountSold,
        address seller
    ) external {
        vm.assume(acceptedToken != IERC20(address(0)));
        vm.assume(tokenAloted != IERC20(address(0)));
        vm.assume(initialPrice > 0);
        vm.assume(duration > 0);
        vm.assume(amountSold > 0);
        vm.assume(seller != address(0));

        // compute the next deployment address
        address nextAddress = vm.computeCreateAddress(address(this), vm.getNonce(address(this)));

        // it should transfer the token being sold to the contract, from the deployer
        mockExpectCall(
            address(tokenAloted),
            abi.encodeCall(IERC20.transferFrom, (address(this), nextAddress, amountSold)),
            abi.encode(true)
        );

        // it should emit an AuctionCreated event
        vm.expectEmit(true, true, true, true, nextAddress);
        emit AuctionCreated(seller, acceptedToken, tokenAloted, amountSold);

        // it should deploy the contract
        ReverseDutchAuction target = new ReverseDutchAuction({
            acceptedToken: acceptedToken,
            tokenAloted: tokenAloted,
            initialPrice: initialPrice,
            minPrice: minPrice,
            duration: duration,
            amountSold: amountSold,
            seller: seller
        });

        // it should set the accepted token
        assertEq(target.ACCEPTED_TOKEN(), acceptedToken);

        // it should set the token being sold
        assertEq(target.TOKEN_ALOTED(), tokenAloted);

        // it should set the initial price
        assertEq(target.INITIAL_PRICE(), initialPrice);

        // it should set the floor price
        assertEq(target.MIN_PRICE(), minPrice);

        // it should set the duration
        assertEq(target.AUCTION_DURATION(), duration);

        // it should set the amount being sold
        assertEq(target.AMOUNT_SOLD(), amountSold);

        // it should set the seller
        assertEq(target.SELLER(), seller);
    }

    function test_RevertWhen_PassingAnEmptyAcceptedToken() external {
        IERC20 acceptedToken = IERC20(address(0));
        IERC20 tokenAloted = IERC20(makeAddr("tokenAloted"));
        uint256 initialPrice = 1;
        uint256 minPrice = 1;
        uint256 duration = 1;
        uint256 amountSold = 1;
        address seller = makeAddr("seller");

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Constructor_WrongTokenIn.selector);

        new ReverseDutchAuction({
            acceptedToken: acceptedToken,
            tokenAloted: tokenAloted,
            initialPrice: initialPrice,
            minPrice: minPrice,
            duration: duration,
            amountSold: amountSold,
            seller: seller
        });
    }

    function test_RevertWhen_PassingAnEmptyTokenBeingSold() external {
        IERC20 acceptedToken = IERC20(makeAddr("acceptedToken"));
        IERC20 tokenAloted = IERC20(address(0));
        uint256 initialPrice = 1;
        uint256 minPrice = 1;
        uint256 duration = 1;
        uint256 amountSold = 1;
        address seller = makeAddr("seller");

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Constructor_WrongTokenOut.selector);

        new ReverseDutchAuction({
            acceptedToken: acceptedToken,
            tokenAloted: tokenAloted,
            initialPrice: initialPrice,
            minPrice: minPrice,
            duration: duration,
            amountSold: amountSold,
            seller: seller
        });
    }

    function test_RevertWhen_PassingAInitialPriceOf0() external {
        IERC20 acceptedToken = IERC20(makeAddr("acceptedToken"));
        IERC20 tokenAloted = IERC20(makeAddr("tokenAloted"));
        uint256 initialPrice = 0;
        uint256 minPrice = 1;
        uint256 duration = 1;
        uint256 amountSold = 1;
        address seller = makeAddr("seller");

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Constructor_InitialPriceZero.selector);

        new ReverseDutchAuction({
            acceptedToken: acceptedToken,
            tokenAloted: tokenAloted,
            initialPrice: initialPrice,
            minPrice: minPrice,
            duration: duration,
            amountSold: amountSold,
            seller: seller
        });
    }

    function test_RevertWhen_PassingA0Duration() external {
        IERC20 acceptedToken = IERC20(makeAddr("tokenAloted"));
        IERC20 tokenAloted = IERC20(makeAddr("tokenAloted"));
        uint256 initialPrice = 1;
        uint256 minPrice = 1;
        uint256 duration = 0;
        uint256 amountSold = 1;
        address seller = makeAddr("seller");

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Constructor_DurationZero.selector);

        new ReverseDutchAuction({
            acceptedToken: acceptedToken,
            tokenAloted: tokenAloted,
            initialPrice: initialPrice,
            minPrice: minPrice,
            duration: duration,
            amountSold: amountSold,
            seller: seller
        });
    }

    function test_RevertWhen_PassingAAmountOf0BeingSold() external {
        IERC20 acceptedToken = IERC20(makeAddr("tokenAloted"));
        IERC20 tokenAloted = IERC20(makeAddr("tokenAloted"));
        uint256 initialPrice = 1;
        uint256 minPrice = 1;
        uint256 duration = 1;
        uint256 amountSold = 0;
        address seller = makeAddr("seller");

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Constructor_AmountSoldZero.selector);

        new ReverseDutchAuction({
            acceptedToken: acceptedToken,
            tokenAloted: tokenAloted,
            initialPrice: initialPrice,
            minPrice: minPrice,
            duration: duration,
            amountSold: amountSold,
            seller: seller
        });
    }

    function test_RevertWhen_PassingAnEmptySeller() external {
        IERC20 acceptedToken = IERC20(makeAddr("tokenAloted"));
        IERC20 tokenAloted = IERC20(makeAddr("tokenAloted"));
        uint256 initialPrice = 1;
        uint256 minPrice = 1;
        uint256 duration = 1;
        uint256 amountSold = 1;
        address seller = address(0);

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Constructor_SellerZero.selector);

        new ReverseDutchAuction({
            acceptedToken: acceptedToken,
            tokenAloted: tokenAloted,
            initialPrice: initialPrice,
            minPrice: minPrice,
            duration: duration,
            amountSold: amountSold,
            seller: seller
        });
    }
}
