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
        kDisplayingModal = 3,
        kGameWon = 4,
        kGameLost = 5
    },
    wordStates = {
        kWordNotInList = 0,
        kWordIncorrect = 1,
        kWordCorrect = 2
    }
}

function randomWord(words)
    return words[math.random(1, #words)]
end
