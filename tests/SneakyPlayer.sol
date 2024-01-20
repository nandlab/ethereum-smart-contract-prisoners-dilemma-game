// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../contracts/PrisonersDilemmaGame.sol";
import "hardhat/console.sol";


contract SneakyPlayer is Ownable, ReentrancyGuard {
    PrisonersDilemmaGame private prisonersDilemma;
    
    constructor(PrisonersDilemmaGame _prisonersDilemma) payable Ownable(msg.sender) {
        Assert.greaterThan(msg.value + 1, uint(10 ether), "I want 10 ether to play");
        prisonersDilemma = _prisonersDilemma;
    }

    function register() external onlyOwner nonReentrant {
        prisonersDilemma.registerNewPlayer{value: 10 ether}();
    }

    function playAgainst(address _otherPlayer) external onlyOwner nonReentrant {
        prisonersDilemma.playAgainst(_otherPlayer);
    }
}
