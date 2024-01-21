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

    receive() external payable {}

    constructor(PrisonersDilemmaGame _prisonersDilemma) payable Ownable(msg.sender) {
        prisonersDilemma = _prisonersDilemma;
        prisonersDilemma.registerNewPlayer{value: msg.value}();
    }

    function getState() external view returns (PrisonersDilemmaGame.PlayerState memory) {
        return prisonersDilemma.getPlayerState(address(this));
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
