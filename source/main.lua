import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "keyboard"
import "support"

local gfx <const> = playdate.graphics

local wordList <const> = import "words"
local word

local directions = {playdate.kButtonUp,
                    playdate.kButtonDown,
                    playdate.kButtonLeft,
                    playdate.kButtonRight}

-- Stuff to model:
-- [x] Word list
    -- [x] Selecting random word
-- [ ] Keyboard
    -- [x] Draw keyboard
    -- [ ] Draw highlighting
    -- [ ] Currently selected key
-- [ ] Board
    -- [ ] Current entry
    -- [ ] Previously entered words
    -- [ ] Position detection/colouring

function setupGame()
    setupKeyboard()

    math.randomseed(playdate.getSecondsSinceEpoch())
    word = randomWord(wordList)
end

setupGame()

function playdate.update()
    for _, button in pairs(directions) do
        if playdate.buttonJustPressed(button) then
            handleInput(button)
        end
    end

    gfx.sprite.update()
end
