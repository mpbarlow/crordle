-- support.lua
--
-- Provides game enum constants, global "knobs and dials", and helper functions.

import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

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

-- Global attributes
letterCount = 5
guessCount = 6

-- The top left co-ordinate of the board
boardOrigin = {x = 10, y = 17}

-- Size of each piece in pixels
pieceSize = {width = 30, height = 30}

-- Space between each piece vertically and horizontally in pixels
pieceMargin = 5

function randomWord(words)
    return words[math.random(1, #words)]
end

-- Run the provided callback inside its own graphics context.
function inGraphicsContext(callback)
    gfx.pushContext()
    callback()
    gfx.popContext()
end
