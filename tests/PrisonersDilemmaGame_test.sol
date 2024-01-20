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
        Assert.equal(address(prisonersDilemma).balance, 0, "Initial prisonersDilemma balance should be zero");
        console.log("Done.");

        console.log("Creating and registering Tit for Tat player...");
        titForTat = new TitForTatPlayer{value: 10 ether}(prisonersDilemma);
        Assert.equal(address(titForTat).balance, 10 ether, "Initial Tit for Tat balance should be 10 Ether");
        titForTat.register();
        Assert.equal(address(titForTat).balance, 0, "Tit for Tat balance should be 0 Ether after registering");
        console.log("Done.");

        console.log("Creating and registering Sneaky player...");
        sneaky = new SneakyPlayer{value: 10 ether}(prisonersDilemma);
        Assert.equal(address(sneaky).balance, 10 ether, "Initial Sneaky balance should be 10 Ether");
        sneaky.register();
        Assert.equal(address(sneaky).balance, 0, "Sneaky balance should be 0 Ether after registering");
        console.log("Done.");
    }

    /* function titForTatVsSneaky() external onlyOwner nonReentrant {
        console.log("Letting Tit for Tat play against Sneaky...");
        titForTat.playAgainst(address(sneaky));
        sneaky.playAgainst(address(titForTat));
        console.log("Done.");
    } */
}
