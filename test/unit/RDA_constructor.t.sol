// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {ReverseDutchAuction, IERC20} from "../../src/ReverseDutchAuction.sol";

contract RDA_Constructor_unitTests is Test {
    // Events to test
    event AuctionCreated(
        address indexed seller, IERC20 indexed acceptedToken, IERC20 indexed tokenAloted, uint256 amountAlotedSold
    );

    function test_WhenPassingCorrectArguments(
        IERC20 _acceptedToken,
        IERC20 _tokenAloted,
        uint256 _initialPrice,
        uint256 _minPrice,
        uint256 _duration,
        uint256 _amountSold,
        address _seller
    ) external {
        vm.assume(_acceptedToken != IERC20(address(0)));
        vm.assume(_tokenAloted != IERC20(address(0)));
        vm.assume(_initialPrice > 0);
        vm.assume(_duration > 0);
        vm.assume(_amountSold > 0);
        vm.assume(_seller != address(0));

        // compute the next deployment address
        address nextAddress = vm.computeCreateAddress(address(this), vm.getNonce(address(this)));

        // it should transfer the token being sold to the contract, from the deployer
        mockExpectCall(
            address(_tokenAloted),
            abi.encodeCall(IERC20.transferFrom, (address(this), nextAddress, _amountSold)),
            abi.encode(true)
        );

        // it should emit an AuctionCreated event
        vm.expectEmit(true, true, true, true, nextAddress);
        emit AuctionCreated(_seller, _acceptedToken, _tokenAloted, _amountSold);

        // it should deploy the contract
        ReverseDutchAuction target = new ReverseDutchAuction({
            _acceptedToken: _acceptedToken,
            _tokenAloted: _tokenAloted,
            _initialPrice: _initialPrice,
            _minPrice: _minPrice,
            _duration: _duration,
            _amountSold: _amountSold,
            _seller: _seller
        });

        // it should set the accepted token
        assertEq(target.ACCEPTED_TOKEN(), _acceptedToken);

        // it should set the token being sold
        assertEq(target.TOKEN_ALOTED(), _tokenAloted);

        // it should set the initial price
        assertEq(target.INITIAL_PRICE(), _initialPrice);

        // it should set the floor price
        assertEq(target.MIN_PRICE(), _minPrice);

        // it should set the duration
        assertEq(target.AUCTION_DURATION(), _duration);

        // it should set the amount being sold
        assertEq(target.AMOUNT_SOLD(), _amountSold);

        // it should set the seller
        assertEq(target.SELLER(), _seller);
    }

    function test_RevertWhen_PassingAnEmptyAcceptedToken() external {
        IERC20 _acceptedToken = IERC20(address(0));
        IERC20 _tokenAloted = IERC20(makeAddr("tokenAloted"));
        uint256 _initialPrice = 1;
        uint256 _minPrice = 1;
        uint256 _duration = 1;
        uint256 _amountSold = 1;
        address _seller = makeAddr("seller");

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Constructor_WrongTokenIn.selector);

        new ReverseDutchAuction({
            _acceptedToken: _acceptedToken,
            _tokenAloted: _tokenAloted,
            _initialPrice: _initialPrice,
            _minPrice: _minPrice,
            _duration: _duration,
            _amountSold: _amountSold,
            _seller: _seller
        });
    }

    function test_RevertWhen_PassingAnEmptyTokenBeingSold() external {
        IERC20 _acceptedToken = IERC20(makeAddr("acceptedToken"));
        IERC20 _tokenAloted = IERC20(address(0));
        uint256 _initialPrice = 1;
        uint256 _minPrice = 1;
        uint256 _duration = 1;
        uint256 _amountSold = 1;
        address _seller = makeAddr("seller");

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Constructor_WrongTokenOut.selector);

        new ReverseDutchAuction({
            _acceptedToken: _acceptedToken,
            _tokenAloted: _tokenAloted,
            _initialPrice: _initialPrice,
            _minPrice: _minPrice,
            _duration: _duration,
            _amountSold: _amountSold,
            _seller: _seller
        });
    }

    function test_RevertWhen_PassingAInitialPriceOf0() external {
        IERC20 _acceptedToken = IERC20(makeAddr("acceptedToken"));
        IERC20 _tokenAloted = IERC20(makeAddr("tokenAloted"));
        uint256 _initialPrice = 0;
        uint256 _minPrice = 1;
        uint256 _duration = 1;
        uint256 _amountSold = 1;
        address _seller = makeAddr("seller");

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Constructor_InitialPriceZero.selector);

        new ReverseDutchAuction({
            _acceptedToken: _acceptedToken,
            _tokenAloted: _tokenAloted,
            _initialPrice: _initialPrice,
            _minPrice: _minPrice,
            _duration: _duration,
            _amountSold: _amountSold,
            _seller: _seller
        });
    }

    function test_RevertWhen_PassingA0Duration() external {
        IERC20 _acceptedToken = IERC20(makeAddr("tokenAloted"));
        IERC20 _tokenAloted = IERC20(makeAddr("tokenAloted"));
        uint256 _initialPrice = 1;
        uint256 _minPrice = 1;
        uint256 _duration = 0;
        uint256 _amountSold = 1;
        address _seller = makeAddr("seller");

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Constructor_DurationZero.selector);

        new ReverseDutchAuction({
            _acceptedToken: _acceptedToken,
            _tokenAloted: _tokenAloted,
            _initialPrice: _initialPrice,
            _minPrice: _minPrice,
            _duration: _duration,
            _amountSold: _amountSold,
            _seller: _seller
        });
    }

    function test_RevertWhen_PassingAAmountOf0BeingSold() external {
        IERC20 _acceptedToken = IERC20(makeAddr("tokenAloted"));
        IERC20 _tokenAloted = IERC20(makeAddr("tokenAloted"));
        uint256 _initialPrice = 1;
        uint256 _minPrice = 1;
        uint256 _duration = 1;
        uint256 _amountSold = 0;
        address _seller = makeAddr("seller");

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Constructor_AmountSoldZero.selector);

        new ReverseDutchAuction({
            _acceptedToken: _acceptedToken,
            _tokenAloted: _tokenAloted,
            _initialPrice: _initialPrice,
            _minPrice: _minPrice,
            _duration: _duration,
            _amountSold: _amountSold,
            _seller: _seller
        });
    }

    function test_RevertWhen_PassingAnEmptySeller() external {
        IERC20 _acceptedToken = IERC20(makeAddr("tokenAloted"));
        IERC20 _tokenAloted = IERC20(makeAddr("tokenAloted"));
        uint256 _initialPrice = 1;
        uint256 _minPrice = 1;
        uint256 _duration = 1;
        uint256 _amountSold = 1;
        address _seller = address(0);

        // it should revert
        vm.expectRevert(ReverseDutchAuction.RDA_Constructor_SellerZero.selector);

        new ReverseDutchAuction({
            _acceptedToken: _acceptedToken,
            _tokenAloted: _tokenAloted,
            _initialPrice: _initialPrice,
            _minPrice: _minPrice,
            _duration: _duration,
            _amountSold: _amountSold,
            _seller: _seller
        });
    }

    /////////////////////////////////////////////////////////////////////
    //                      Internal test helpers                      //
    /////////////////////////////////////////////////////////////////////

    function assertEq(IERC20 a, IERC20 b) internal pure {
        assertEq(address(a), address(b));
    }

    function mockExpectCall(address target, bytes memory callData, bytes memory returnedData) internal {
        vm.mockCall(target, callData, returnedData);
        vm.expectCall(target, callData);
    }
}
