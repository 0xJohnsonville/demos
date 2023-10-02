// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    enum Choice {
        None,
        Rock,
        Paper,
        Scissors
    }
    enum GameState {
        Created,
        Played
    }

    struct Game {
        address player1;
        address player2;
        uint256 betAmount;
        Choice choice1;
        Choice choice2;
        GameState state;
    }

    uint256 public gameId;
    address public owner;

    mapping(uint256 => Game) public games;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function createGame() external payable {
        require(msg.value > 0, "Bet amount must be greater than 0");
        gameId++;
        Game storage newGame = games[gameId];
        newGame.player1 = msg.sender;
        newGame.betAmount = msg.value;
        newGame.state = GameState.Created;
    }

    function joinGame(uint256 _gameId, Choice _choice) external payable {
        Game storage game = games[_gameId];
        require(
            game.state == GameState.Created,
            "Game is not in the Created state"
        );
        require(msg.sender != game.player1, "You cannot play against yourself");
        require(
            msg.value == game.betAmount,
            "Bet amount must match the first player's bet"
        );

        game.player2 = msg.sender;
        game.choice1 = Choice(
            uint8(
                uint256(
                    keccak256(abi.encodePacked(block.timestamp, msg.sender))
                ) % 3
            ) + 1
        ); // Pseudo-random choice for player1
        game.choice2 = _choice;
        game.state = GameState.Played;

        // Determine the winner
        Choice winner = determineWinner(game.choice1, game.choice2);
        if (winner == Choice.Rock) {
            payable(game.player1).transfer(game.betAmount * 2);
        } else if (winner == Choice.Paper) {
            payable(game.player2).transfer(game.betAmount * 2);
        } else {
            payable(game.player1).transfer(game.betAmount); // Refund if it's a tie
            payable(game.player2).transfer(game.betAmount);
        }
    }

    function determineWinner(
        Choice _choice1,
        Choice _choice2
    ) internal pure returns (Choice) {
        if (_choice1 == _choice2) {
            return Choice.None; // Tie
        } else if (_choice1 == Choice.Rock && _choice2 == Choice.Scissors) {
            return Choice.Rock;
        } else if (_choice1 == Choice.Paper && _choice2 == Choice.Rock) {
            return Choice.Paper;
        } else if (_choice1 == Choice.Scissors && _choice2 == Choice.Paper) {
            return Choice.Scissors;
        } else {
            return Choice.None; // Player 2 wins
        }
    }
}
