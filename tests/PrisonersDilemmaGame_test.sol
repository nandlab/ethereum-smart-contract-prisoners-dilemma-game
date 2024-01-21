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

    constructor() Ownable(msg.sender) {}

    ///#value: 20000000000000000000
    function beforeAll() external payable onlyOwner nonReentrant {
        Assert.greaterThan(msg.value + 1, uint(20 ether), "I should get at least 20 Ether");
        console.log("Deploying PrisonersDilemmaGame...");
        prisonersDilemma = new PrisonersDilemmaGame();
        console.log("Done. PrisonersDilemmaGame address: %s", address(prisonersDilemma));
        Assert.equal(address(prisonersDilemma).balance, 0, "Initial prisonersDilemma balance should be zero");

        console.log("Creating and registering Tit for Tat player...");
        titForTat = new TitForTatPlayer{value: 10 ether}(prisonersDilemma);
        console.log("Done. TitForTat address: %s", address(titForTat));
        Assert.equal(address(titForTat).balance, 0, "Tit for Tat balance should be 0 Ether after registering");

        console.log("Creating and registering Sneaky player...");
        sneaky = new SneakyPlayer{value: 10 ether}(prisonersDilemma);
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
        titForTat.playAgainst(address(sneaky));
        sneaky.playAgainst(address(titForTat));
        uint roundNumber = 0;
        while (matchRunning()) {
            console.log("Round %d", roundNumber);
            console.log("Tit for Tat does an action");
            titForTat.doAction();
            console.log("Sneaky does an action");
            sneaky.doAction();
            console.log("");
            roundNumber++;
        }
        Assert.ok(titForTat.getState().lastMatchOutcome == - sneaky.getState().lastMatchOutcome, "The players should be in consensus about the match outcome");
        console.log("Done.");
    }
}
