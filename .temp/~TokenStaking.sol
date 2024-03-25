// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;
import "d:/Fuzen/fuzen-smart-contract/node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract TokenStaking is Ownable {

    constructor(address _initialOwner) Ownable(_initialOwner){
        
    }
}