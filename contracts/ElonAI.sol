// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ELONAI is ERC20 {
    constructor() ERC20("ELONAI", "EL") 
    {
        _mint(msg.sender, 1000*10**decimals());
    }
}
