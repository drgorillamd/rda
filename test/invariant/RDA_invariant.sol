// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ReverseDutchAuction, IERC20} from "../../src/ReverseDutchAuction.sol";
import {MockERC20Mintable} from "../lib/MockERC20Mintable.sol";
import {IWETH9} from "./../lib/IWETH9.sol";
import {RDA_Handler} from "./RDA_handler.sol";

/// @notice 
/// "global balance conservation" invariants:
/// - invOne: The global (buyer + seller + auction contract) alloted token balance should remain the same
/// - invTwo: The global accepted token balance should remain the same
///

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

    function invariant_invOne() public view {
        assertEq(
            handler.ghost_balanceBuyerAcceptedTokenBefore() + handler.ghost_balanceSellerAcceptedTokenBefore()
                + handler.ghost_balanceContractAcceptedTokenBefore(),
            handler.ghost_balanceBuyerAcceptedTokenAfter() + handler.ghost_balanceSellerAcceptedTokenAfter()
                + handler.ghost_balanceContractAcceptedTokenAfter()
        );
    }

    function invariant_invTwo() public view {
        assertEq(
            handler.ghost_balanceBuyerTokenAlotedBefore() + handler.ghost_balanceSellerTokenAlotedBefore()
                + handler.ghost_balanceContractTokenAlotedBefore(),
            handler.ghost_balanceBuyerTokenAlotedAfter() + handler.ghost_balanceSellerTokenAlotedAfter()
                + handler.ghost_balanceContractTokenAlotedAfter()
        );
    }
}
