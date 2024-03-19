// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Fuzion is ERC20 {
    constructor() ERC20("Fuzion", "FZN") {
        _mint(msg.sender, 1_000_000_000 ether);
    }
}