import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "BoardSquare"
import "support"

local gfx <const> = playdate.graphics

local wordList <const> = import "words"
local word

local rotationDivisor <const> = 2

local boardSquare = BoardSquare({x = 10, y = 10}, {width = 30, height = 30})

function playdate.update()
    local change, acceleratedChange = playdate.getCrankChange()

    if (acceleratedChange ~= 0) then
        boardSquare:moveOffset(acceleratedChange / rotationDivisor)
    end

    for _, button in pairs({playdate.kButtonUp, playdate.kButtonDown}) do
        if (playdate.buttonJustPressed(button)) then
            boardSquare:handleInput(button)
        end
    end

    -- If we've configured an animator, get the next value and update our current offset to it.
    if (boardSquare.animator ~= nil) then
        boardSquare:setOffset(boardSquare.animator:currentValue())

        if (boardSquare.animator:ended()) then
            boardSquare.animator = nil
        end
    end

    gfx.sprite.update()
    playdate.drawFPS(380, 225)
end
