// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "hardhat/console.sol";


/**
 * @title PrisonersDilemmaGame
 * @dev Prisoner's dilemma as a multiplayer game
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract PrisonersDilemmaGame is ReentrancyGuard
{
    uint16 public constant MAX_ROUNDS = 25;

    enum Action {
        None,
        Cooperate,
        Defect
    }

    function actionToString(Action _action) public pure returns (string memory) {
        return ["None", "Cooperate", "Defect"][uint(_action)];
    }

    struct PlayerState {
        bool registered;
        uint matchScore;
        uint xp;
        address opponent;
        bool actionSubmittedSecretly;
        uint actionHash;
        Action action;
        Action lastAction;
        int8 lastMatchOutcome; // -1: Lose, 0: Draw, 1: Win
        uint16 round;
    }

    address[] private players;
    mapping (address => PlayerState) private playerStates;
    uint private randCounter;

    function getPlayerState(address _player) public view returns (PlayerState memory) {
        return playerStates[_player];
    }

    function getAllPlayerStates() public view returns (address[] memory, PlayerState[] memory) {
        PlayerState[] memory playerStatesArray = new PlayerState[](players.length);
        for (uint i = 0; i < players.length; i++) {
            playerStatesArray[i] = (playerStates[players[i]]);
        }
        return (players, playerStatesArray);
    }

    function random() private returns (uint rand) {
        rand = uint(keccak256(abi.encode(
            block.prevrandao,
            address(this),
            randCounter
        )));
        randCounter++;
    }

    function getReward(Action myAction, Action opponentAction) public pure returns(uint8 myReward, uint8 opponentReward) {
        require(myAction != Action.None && opponentAction != Action.None);
        if (myAction == Action.Cooperate) {
            if (opponentAction == Action.Cooperate) {
                myReward = 3;
                opponentReward = 3;
            }
            else {
                myReward = 0;
                opponentReward = 5;
            }
        }
        else {
            if (opponentAction == Action.Cooperate) {
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
        require(!playerStates[msg.sender].registered, "You are already registered");
        require(msg.value >= 1 ether, "You have to deposit at least 1 ETH to register");
        players.push(payable(msg.sender));
        playerStates[msg.sender] = PlayerState(true, 0, 0, payable(address(0)), false, 0, Action.None, Action.None, 0, 0);
    }

    // Asserts that the user calling this contract is registered and
    // returns a boolean whether he is currently in a match with another player.
    function isInMatch() public view returns (bool) {
        PlayerState storage myState = playerStates[msg.sender];
        require(myState.registered, "User not registered");
        return playerStates[myState.opponent].opponent == msg.sender;
    }

    // The game starts if both players are ready to play against each other
    function playAgainst(address _otherPlayer) external nonReentrant {
        require(!isInMatch(), "Cannot change opponent while playing a match");
        require(_otherPlayer != address(this), "Cannot play against yourself");
        require(_otherPlayer != address(0) && playerStates[_otherPlayer].registered, "Requested opponent does not exist");
        playerStates[msg.sender].opponent = _otherPlayer;
    }

    /**
     * In each round each player has to submit their action.
     * Each player first submits a hash of his action and can later reveals it,
     * when the other player also submitted his action hash.
     * Therefore one player cannot wait for the opponent to choose an action
     * and then choose his own action based on the opponent's.
     * To reveal an action, the action itself and a pepper is sent.
     * The number of rounds is not deterministic.
     * After each round there is a 25% possibility that the match is completed.
     */

    // The client should hash the action as follows with a secret pepper:
    // uint(keccak256(abi.encode(action, pepper));
    function submitActionSecretly(uint actionHash) external nonReentrant {
        require(isInMatch(), "No match is running");
        PlayerState storage myState = playerStates[msg.sender];
        require(!myState.actionSubmittedSecretly, "Action already submitted");
        myState.actionHash = actionHash;
        myState.actionSubmittedSecretly = true;
    }

    function revealAction(Action _action, uint _pepper) external nonReentrant {
        PlayerState storage myState = playerStates[msg.sender];
        require(isInMatch(), "No match is running");
        require(myState.actionSubmittedSecretly, "No action submitted yet");
        require(uint(keccak256(abi.encode(_action, _pepper))) == myState.actionHash, "Action with pepper do not match hash");
        myState.action = _action;
        // If both players have disclosed their action, the round outcome is evaluated
        if (playerStates[myState.opponent].action != Action.None) {
           console.log("PrisonersDilemmaGame: Both players have revealed their action");
           evaluateRoundOutcome();
        }
    }

    function evaluateRoundOutcome() internal {
        PlayerState storage myState = playerStates[msg.sender];
        address opponent = myState.opponent;
        PlayerState storage opponentState = playerStates[opponent];
        (uint8 myReward, uint8 opponentReward) = getReward(myState.action, opponentState.action);
        console.log("PrisonersDilemmaGame: Round result:");
        console.log("* %s: Action: %s, Reward: %d", msg.sender, actionToString(myState.action), myReward);
        console.log("* %s: Action: %s, Reward: %d", opponent, actionToString(opponentState.action), opponentReward);
        myState.matchScore += myReward;
        opponentState.matchScore += opponentReward;
        // Round completed
        myState.actionSubmittedSecretly = false;
        myState.actionHash = 0;
        myState.lastAction = myState.action;
        myState.action = Action.None;
        opponentState.actionSubmittedSecretly = false;
        opponentState.actionHash = 0;
        opponentState.lastAction = opponentState.action;
        opponentState.action = Action.None;
        myState.round++;
        opponentState.round++;
        // With 1/4 probability the match finishes, otherwise it continues
        if (myState.round >= MAX_ROUNDS || random() % 4 == 0) {
            console.log("PrisonersDilemmaGame: Match is finished");
            address payable winner;
            if (myState.matchScore > opponentState.matchScore) {
                // I won!
                myState.lastMatchOutcome = 1;
                opponentState.lastMatchOutcome = -1;
                winner = payable(msg.sender);
                console.log("PrisonersDilemmaGame: The winner is: %s", winner);
            }
            else if (myState.matchScore < opponentState.matchScore) {
                // Opponent won!
                myState.lastMatchOutcome = -1;
                opponentState.lastMatchOutcome = 1;
                winner = payable(opponent);
                console.log("PrisonersDilemmaGame: The winner is: %s", winner);
            }
            else {
                myState.lastMatchOutcome = 0;
                opponentState.lastMatchOutcome = 0;
                console.log("PrisonersDilemmaGame: Draw");
            }
            // The winner gets 0.1 ETH
            uint balance = address(this).balance;
            if (winner != address(0) && balance > 0) {
                uint etherReward = 0.1 ether;
                uint val = etherReward < balance ? etherReward : balance;
                (bool success,) = winner.call{value: val}("");
                require(success);
                console.log("PrisonersDilemmaGame: Ether reward was sent to the winner");
            }
            myState.xp += myState.matchScore;
            myState.matchScore = 0;
            myState.opponent = payable(address(0));
            myState.lastAction = Action.None;
            myState.round = 0;
            opponentState.xp += opponentState.matchScore;
            opponentState.matchScore = 0;
            opponentState.opponent = payable(address(0));
            opponentState.lastAction = Action.None;
            opponentState.round = 0;
            console.log("PrisonersDilemmaGame: Player states finalized");
        }
        else {
            console.log("PrisonersDilemmaGame: Next round");
        }
    }
}
