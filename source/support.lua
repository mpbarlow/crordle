-- Game state constants.
kLetterStateUnchecked = 0
kLetterStateWrongLocation = 1
kLetterStateIncorrect = 2
kLetterStateCorrect = 3

kGameStateEnteringWord = 0
kGameStateSubmittingWord = 1
kGameStateCheckingEntry = 2
kGameStateGameWon = 3
kGameStateGameLost = 4

kEventGameStateDidTransition = 0
kEventEnteredWordNotInList = 1
kEventGameWon = 2
kEventGameLost = 3

kWordStateNotInList = 0
kWordStateIncorrect = 1
kWordStateCorrect = 2

-- Global attributes.
letterCount = 5
guessCount = 6

boardOrigin = {x = 10, y = 17}
pieceSize = {width = 30, height = 30}
pieceMargin = 5

function randomWord(words)
    return words[math.random(1, #words)]
end
