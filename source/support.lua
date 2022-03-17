constants = {
    pieceStates = {
        kSquareUnchecked = 0,
        kSquareWrongLocation = 1,
        kSquareIncorrect = 2,
        kSquareCorrect = 3
    },
    gameStates = {
        kWordEntry = 0,
        kWordSubmit = 1,
        kCheckingEntry = 2
    }
}

function randomWord(words)
    return words[math.random(1, #words)]
end
