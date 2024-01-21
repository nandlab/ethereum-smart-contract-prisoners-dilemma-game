// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../contracts/PrisonersDilemmaGame.sol";
import "hardhat/console.sol";


abstract contract Player is Ownable, ReentrancyGuard {
    PrisonersDilemmaGame internal prisonersDilemma;
    address internal opponent;

    constructor(PrisonersDilemmaGame _prisonersDilemma) payable Ownable(msg.sender) {
        Assert.greaterThan(msg.value + 1, uint(10 ether), "I want 10 ETH to play");
        prisonersDilemma = _prisonersDilemma;
        prisonersDilemma.registerNewPlayer{value: 10 ether}();
    }

    function getState() external view returns (PrisonersDilemmaGame.PlayerState memory) {
        return prisonersDilemma.getPlayerState(msg.sender);
    }

    function isInMatch() external view returns (bool) {
        return prisonersDilemma.isInMatch();
    }

    function playAgainst(address _otherPlayer) external onlyOwner nonReentrant {
        opponent = _otherPlayer;
        prisonersDilemma.playAgainst(opponent);
    }

    function doAction() external virtual;
}
