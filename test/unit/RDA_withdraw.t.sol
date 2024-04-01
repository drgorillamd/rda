// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console, stdStorage, StdStorage} from "forge-std/Test.sol";
import {Utils} from "../lib/utils.sol";
import {MockERC20Mintable} from "../lib/MockERC20Mintable.sol";

import {ReverseDutchAuction, IERC20} from "../../src/ReverseDutchAuction.sol";

contract RDA_Withdraw_unitTests is Test, Utils {
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
            _acceptedToken: acceptedToken,
            _tokenAloted: tokenAloted,
            _initialPrice: initialPrice,
            _minPrice: minPrice,
            _duration: duration,
            _amountSold: amountSold,
            _seller: seller
        });
    }

    function test_WithdrawRevertWhen_TheAuctionHasNotExpired(uint256 _auctionProgression) external {
        _auctionProgression = bound(_auctionProgression, 0, duration);
        vm.warp(block.timestamp + _auctionProgression);

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Withdraw_AuctionNotExpired.selector);

        target.withdrawExpiredAuction();
    }

    function test_WithdrawWhenTheAuctionHasExpired(uint256 _auctionProgression) external {
        // it should transfer the aloted token back to the seller

        _auctionProgression = bound(_auctionProgression, duration + 1, type(uint128).max);
        vm.warp(block.timestamp + _auctionProgression);

        mockExpectCall(address(tokenAloted), abi.encodeCall(IERC20.transfer, (seller, amountSold)), abi.encode(true));

        target.withdrawExpiredAuction();
    }
}
