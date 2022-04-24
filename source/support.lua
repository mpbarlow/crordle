-- support.lua
-- Provides game enum constants, global "knobs and dials", and helper functions.

import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

-- Game state constants.
kLetterStateWrongLocation = 0
kLetterStateIncorrect = 1
kLetterStateCorrect = 2

kGameStateEnteringWord = 0
kGameStateSubmittingWord = 1
kGameStateCheckingEntry = 2
kGameStateWon = 3
kGameStateLost = 4

kUIStatePlayingGame = 0
kUIStateDisplayingModal = 1

kEventGameStateDidTransition = 0
kEventEnteredWordNotInList = 1

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

fonts = {
    small = gfx.font.new("fonts/Roobert-10-Bold"),
    regular = gfx.font.new("fonts/Roobert-11-Medium"),
}

-- Run the provided callback inside its own graphics context. Useful if the callback has multiple
-- return points and you don't want to have to track popping the context in all of them.
function doInGraphicsContext(callback)
    gfx.pushContext()
    callback()
    gfx.popContext()
end

-- Additional table functions
function table.randomElement(t)
    return t[math.random(1, #t)]
end

-- Returns a string breaking down the stats in the provided table.
function getGameStatsDescription(statsTable)
    local winPercentage <const> = math.floor((statsTable.won / statsTable.played) * 100)

    return "Won "
        .. statsTable.won
        .. "/"
        .. statsTable.played
        .. " ("
        .. winPercentage
        .. "%), streak "
        .. statsTable.streak
        .. "."
end
