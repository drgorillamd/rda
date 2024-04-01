// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {MockERC20} from "forge-std/mocks/MockERC20.sol";

contract MockERC20Mintable is MockERC20 {
    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }
}
