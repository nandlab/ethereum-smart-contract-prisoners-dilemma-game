// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Player.sol";
import "hardhat/console.sol";


contract SneakyPlayer is Player {
    uint private sneakyRandomCtr;
    
    constructor(PrisonersDilemmaGame _prisonersDilemma) payable Player(_prisonersDilemma) {}

    function sneakyRandom() private returns (uint) {
        uint rand = uint(keccak256(abi.encode(
            block.prevrandao, address(this), prisonersDilemma, sneakyRandomCtr
        )));
        sneakyRandomCtr++;
        return rand;
    }

    function getAction() internal override returns (PrisonersDilemmaGame.Action) {
        // Start by cooperating, then mirror the oppenent's behaviour
        PrisonersDilemmaGame.Action lastOpponentAction = prisonersDilemma.getPlayerState(opponent).lastAction;
        PrisonersDilemmaGame.Action action = PrisonersDilemmaGame.Action.Cooperate;
        if (lastOpponentAction != PrisonersDilemmaGame.Action.None) {
            action = lastOpponentAction;
        }
        // Defect in 10% of the rounds as a surprise attack
        if (sneakyRandom() % 10 == 0) {
            action = PrisonersDilemmaGame.Action.Defect;
        }
        console.log("SneakyPlayer: choosing to %s", prisonersDilemma.actionToString(action));
        return action;
    }
}
