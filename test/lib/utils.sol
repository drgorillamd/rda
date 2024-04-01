// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Utils is Test {
    function assertEq(IERC20 a, IERC20 b) internal pure {
        assertEq(address(a), address(b));
    }

    function mockExpectCall(address target, bytes memory callData, bytes memory returnedData) internal {
        vm.mockCall(target, callData, returnedData);
        vm.expectCall(target, callData);
    }
}
