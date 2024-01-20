// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PrisonersDilemmaGame
 * @dev Prisoner's dilemma as a multiplayer game
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract PrisonersDilemmaGame is ReentrancyGuard {
    enum Action {
        None,
        Collaborate,
        Defect
    }

    struct PlayerState {
        bool registered;
        uint matchScore;
        uint totalScore;
        address opponent;
        Action action;
        uint ctr;
    }

    address[] private players;
    mapping (address => PlayerState) private playerStates;

    function getPlayerState(address _player) public view returns (PlayerState memory) {
        return playerStates[_player];
    }

    function random(address _playerA, address _playerB) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(
            block.timestamp,
            _playerA, _playerB,
            playerStates[_playerA].ctr, playerStates[_playerB].ctr
        )));
    }

    function getReward(Action myAction, Action opponentAction) public pure returns(uint8 myReward, uint8 opponentReward) {
        require(myAction != Action.None && opponentAction != Action.None);
        if (myAction == Action.Collaborate) {
            if (opponentAction == Action.Collaborate) {
                myReward = 3;
                opponentReward = 3;
            }
            else {
                myReward = 0;
                opponentReward = 5;
            }
        }
        else {
            if (opponentAction == Action.Collaborate) {
                myReward = 5;
                opponentReward = 0;
            }
            else {
                myReward = 1;
                opponentReward = 1;
            }
        }
    } 

    function getPlayer(uint _index) external view returns (address) {
        return players[_index];
    }

    function getPlayerCount() external view returns (uint) {
        return players.length;
    }

    function getAllPlayers() external view returns (address[] memory) {
        return players;
    }

    function registerNewPlayer() external payable nonReentrant {
        require(msg.value == 10 ether);
        players.push(payable(msg.sender));
        playerStates[msg.sender] = PlayerState(true, 0, 0, payable(address(0)), Action.None, 0);
    }

    function playAgainst(address _otherPlayer) external nonReentrant {
        PlayerState storage myState = playerStates[msg.sender];
        require(myState.registered);
        require(_otherPlayer != address(0) && myState.opponent == address(0) && playerStates[_otherPlayer].registered);
        myState.opponent = _otherPlayer;
    }

    function submitAction(Action _action) external nonReentrant {
        /* The game starts if both players are ready to play against each other */
        PlayerState storage myState = playerStates[msg.sender];
        require(myState.registered);
        address opponent = myState.opponent;
        PlayerState storage opponentState = playerStates[opponent];
        require(opponent != address(0) && myState.opponent == address(this) && myState.action == Action.None);
        myState.action = _action;
        if (opponentState.action != Action.None) {
            (uint8 myReward, uint8 opponentReward) = getReward(myState.action, opponentState.action);
            myState.matchScore += myReward;
            opponentState.matchScore += opponentReward;
            // Round completed, reset actions
            myState.action = Action.None;
            opponentState.action = Action.None;
            // With 3/4 probability we continue this match, otherwise it is completed
            if (random(msg.sender, opponent) % 4 == 0) {
                // The winner gets 0.1 ETH
                uint etherReward = 0.1 ether;
                uint balance = address(this).balance;
                if (balance > 0) {
                    uint val = etherReward > balance ? etherReward : balance;
                    if (myState.matchScore > opponentState.matchScore) {
                        // I won!
                        (bool success,) = msg.sender.call{value: val}("");
                        require(success);
                    }
                    else if (myState.matchScore < opponentState.matchScore) {
                        // Opponent won!
                        (bool success,) = msg.sender.call{value: val}("");
                        require(success);
                    }
                }
                myState.totalScore += myState.matchScore;
                myState.matchScore = 0;
                myState.opponent = payable(address(0));
                opponentState.totalScore += opponentState.matchScore;
                opponentState.matchScore = 0;
                opponentState.opponent = payable(address(0));
            }
        }
        myState.ctr++;
    }
}
