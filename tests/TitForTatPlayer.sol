// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Player.sol";
import "hardhat/console.sol";


contract TitForTatPlayer is Player {
    constructor(PrisonersDilemmaGame _prisonersDilemma) payable Player(_prisonersDilemma) {}

    function getAction() internal view override returns (PrisonersDilemmaGame.Action) {
        // Start by cooperating, then mirror the oppenent's behaviour
        PrisonersDilemmaGame.Action action = PrisonersDilemmaGame.Action.Cooperate;
        PrisonersDilemmaGame.Action lastOpponentAction = prisonersDilemma.getPlayerState(opponent).lastAction;
        if (lastOpponentAction != PrisonersDilemmaGame.Action.None) {
            action = lastOpponentAction;
        }
        console.log("TitForTat: choosing to %s", prisonersDilemma.actionToString(action));
        return action;
    }
}
