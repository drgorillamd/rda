// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ReverseDutchAuction, IERC20} from "../../src/ReverseDutchAuction.sol";
import {MockERC20Mintable} from "../lib/MockERC20Mintable.sol";
import {IWETH9} from "./../lib/IWETH9.sol";
import {RDA_Handler} from "./RDA_handler.sol";

/// @notice The invariants which should hold are:


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

    function invariant_one() public {
        vm.skip(true);
    }
}
