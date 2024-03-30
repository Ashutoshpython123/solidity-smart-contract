// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/SafeMath.sol";

contract FuzionAirdrop is Ownable {
    IERC20 public token;

    mapping(address => uint256) public userTokenReceived;

    constructor(address _token, address _initialOwner) Ownable(_initialOwner) {
        token = IERC20(_token);
    }

    function setToken(address _token) public onlyOwner {
        token = IERC20(_token);
    }

    function airdropTokens(address[] memory recipients, uint256[] memory amounts) public onlyOwner {
        require(recipients.length == amounts.length, "Input arrays must have the same length");

        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], amounts[i]);
            userTokenReceived[recipients[i]] += amounts[i];
        }
    }
}