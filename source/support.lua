constants = {
    pieceStates = {
        kPieceUnchecked = 0,
        kPieceWrongLocation = 1,
        kPieceIncorrect = 2,
        kPieceCorrect = 3
    },
    gameStates = {
        kWordEntry = 0,
        kWordSubmit = 1,
        kCheckingEntry = 2,
        kGameWon = 3,
        kGameLost = 4
    },
    gameEvents = {
        kStateTransitioned = 0,
        kWordNotInList = 1,
        kGameWon = 2,
        kGameLost = 3
    },
    wordStates = {
        kWordNotInList = 0,
        kWordIncorrect = 1,
        kWordCorrect = 2
    }
}

letters = 5
guesses = 6

boardOrigin = {x = 10, y = 17}
pieceSize = {width = 30, height = 30}
pieceMargin = 5

function randomWord(words)
    return words[math.random(1, #words)]
end
