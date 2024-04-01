// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ReverseDutchAuction, IERC20} from "../../src/ReverseDutchAuction.sol";
import {IWETH9} from "./../lib/IWETH9.sol";

contract RDA_Integration_forkTest is Test {
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 arb = IERC20(0xB50721BCf8d664c30412Cfbc6cf7a15145234ad1);

    uint256 initialPrice;
    uint256 minPrice;
    uint256 duration;
    uint256 amountSold;
    address seller;
    address buyer;

    ReverseDutchAuction target;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");

        initialPrice = 0.0046 ether; // 1 arb = 0.0046 weth
        minPrice = 0.001 ether; // 1 arb = 0.001 weth
        duration = 10 days;
        amountSold = 200 ether; // 200 arb
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");

        deal(address(arb), seller, amountSold, true);

        // deploy the contract
        vm.startPrank(seller);

        address nextDeploymentAddress = vm.computeCreateAddress(seller, vm.getNonce(seller));

        arb.approve(nextDeploymentAddress, amountSold);

        target = new ReverseDutchAuction({
            acceptedToken: weth,
            tokenAloted: arb,
            initialPrice: initialPrice,
            minPrice: minPrice,
            duration: duration,
            amountSold: amountSold,
            seller: seller
        });

        vm.stopPrank();
    }

    function test_createValidBidShouldSettle() public {
        // We warp at the middle of the auction
        vm.warp(block.timestamp + duration / 2);

        // the current price is (we start at timestamp 0, as the warp is relative): 0.0046 - 0.0046 * (5 days) / 10 days = 0.0023 weth/arb
        // amount sold is 200 arb, so 0.46weth worth - buyer offer a price of 0.0025, or 0.5 weth for the 200 arb
        uint256 proposedPrice = 0.0025 ether;

        // track the balances to test them (makeAddr("buyer") is most likely starting at 0 weth)
        uint256 balanceArbBefore = arb.balanceOf(buyer);
        deal(address(weth), buyer, amountSold * proposedPrice, false);

        // Test: bid for the lot
        vm.startPrank(buyer);
        weth.approve(address(target), amountSold * proposedPrice);
        target.bid(proposedPrice);
        vm.stopPrank();

        // Check: Buyer balances are updated?
        // the weth should be 0, the arb should have been the amount sold
        uint256 balanceArbAfter = arb.balanceOf(buyer);
        uint256 balanceWethAfter = weth.balanceOf(buyer);

        assertEq(balanceArbAfter, balanceArbBefore + amountSold);
        assertEq(balanceWethAfter, 0);
    }
}
