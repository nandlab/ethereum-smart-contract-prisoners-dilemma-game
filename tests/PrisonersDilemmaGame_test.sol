// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../contracts/PrisonersDilemmaGame.sol";
import "hardhat/console.sol";
import "./TitForTatPlayer.sol";
import "./SneakyPlayer.sol";


contract PrisonersDilemmaGameTest is Ownable, ReentrancyGuard {
    PrisonersDilemmaGame private prisonersDilemma;
    TitForTatPlayer private titForTat;
    SneakyPlayer private sneaky;

    constructor() Ownable(msg.sender) {
        console.log("Test deployed by %s", msg.sender);
    }

    ///#value: 2000000000000000000
    function beforeAll() external payable onlyOwner nonReentrant {
        Assert.greaterThan(msg.value + 1, uint(2 ether), "I should get at least 2 Ether");
        console.log("Deploying PrisonersDilemmaGame...");
        prisonersDilemma = new PrisonersDilemmaGame();
        console.log("Done. PrisonersDilemmaGame address: %s", address(prisonersDilemma));
        Assert.equal(address(prisonersDilemma).balance, 0, "Initial prisonersDilemma balance should be zero");

        console.log("Creating and registering Tit for Tat player...");
        titForTat = new TitForTatPlayer{value: 1 ether}(prisonersDilemma);
        console.log("Done. TitForTat address: %s", address(titForTat));
        Assert.equal(address(titForTat).balance, 0, "Tit for Tat balance should be 0 Ether after registering");

        console.log("Creating and registering Sneaky player...");
        sneaky = new SneakyPlayer{value: 1 ether}(prisonersDilemma);
        console.log("Done. Sneaky address: %s", address(sneaky));
        Assert.equal(address(sneaky).balance, 0, "Sneaky balance should be 0 Ether after registering");
    }

    // view keyword is not possible here for some reason
    function matchRunning() internal returns (bool) {
        Assert.ok(titForTat.isInMatch() == sneaky.isInMatch(), "TitForTat and Sneaky should be in consensus of whether they are both in a match or not");
        return titForTat.isInMatch();
    }

    function titForTatVsSneaky() external onlyOwner nonReentrant {
        console.log("Letting Tit for Tat play against Sneaky...");
        uint titForTatBalance = address(titForTat).balance;
        uint sneakyBalance = address(sneaky).balance;
        titForTat.playAgainst(address(sneaky));
        sneaky.playAgainst(address(titForTat));
        uint round = 0;
        while (matchRunning()) {
            console.log("Round %d", round);
            console.log("Tit for Tat submits their action secretly");
            titForTat.doAction();
            console.log("Sneaky submits their action secretly");
            sneaky.doAction();
            console.log("Tit for Tat reveals their action");
            titForTat.revealAction();
            console.log("Sneaky reveals their action");
            sneaky.revealAction();
            console.log("");
            round++;
        }
        console.log("Match finished after %d rounds.", round);
        int8 titForTatMatchOutcome = titForTat.getState().lastMatchOutcome;
        int8 sneakyMatchOutcome = sneaky.getState().lastMatchOutcome;
        uint titForTatNewBalance = address(titForTat).balance;
        uint sneakyNewBalance = address(sneaky).balance;
        console.log("Match outcome for TitForTat:");
        console.logInt(titForTatMatchOutcome);
        console.log("Match outcome for Sneaky:");
        console.logInt(sneakyMatchOutcome);
        Assert.ok(titForTatMatchOutcome == - sneakyMatchOutcome, "The players should be in consensus about the match outcome");
        if (titForTatMatchOutcome > 0) {
            uint actualReward = titForTatNewBalance - titForTatBalance;
            console.log("TitForTat got %d Wei", actualReward);
            Assert.equal(actualReward, 0.1 ether, "TitForTat did not get the expected ETH reward");
        }
        else {
            Assert.equal(titForTatNewBalance, titForTatBalance, "TitForTat's balance should not have changed");
        }
        if (sneakyMatchOutcome > 0) {
            uint actualReward = sneakyNewBalance - sneakyBalance;
            console.log("Sneaky got %d Wei", actualReward);
            Assert.equal(actualReward, 0.1 ether, "Sneaky did not get the expected ETH reward");
        }
        else {
            Assert.equal(sneakyNewBalance, sneakyBalance, "Sneaky's balance should not have changed");
        }
    }
}
