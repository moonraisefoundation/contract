// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MoonRaiseToken is ERC20 {
    uint256 maxSupply = 100_000_000 ether;

    constructor() ERC20("MoonRaise", "MRT") {
        _mint(_msgSender(), maxSupply);
    }

}
