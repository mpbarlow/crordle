import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "support"
import "Game"
import "Selection"
import "SubmitButton"
import "Modal"

local gfx <const> = playdate.graphics
local word = "hello"

-- Helper object to handle drawing a sprite around the active piece to show a selected state.
local selection = Selection(boardOrigin, pieceSize, pieceMargin)
local submitButton = SubmitButton()
local modal = Modal()

-- Tracks the state for the current game.
local game = Game(word)

-- An 8x8 pattern that has a white background with a single block dot (approximate) in the center.
local dotPattern <const> = {0xFF, 0xFF, 0xFF, 0xEF, 0xFF, 0xFF, 0xFF, 0xFF}

-- Perform the initial set up to configure the game board and UI.
selection:moveTo(game:getCurrentRow(), game:getCurrentPosition())

gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
    gfx.setClipRect(x, y, width, height)
    gfx.setPattern(dotPattern)
    gfx.fillRect(x, y, width, height)
    gfx.clearClipRect()
end)

-- To avoid having to implement a latch system where we check the game state each update and ensure
-- we only react to each change once, we instead have a nice event system where the game will call
-- our functions in response to various state changes.
local function registerEvents()
    game.listeners[kEventGameStateDidTransition] = function(game, newState)
        -- If we move into submission mode, we want to hide the selection ring and highlight the
        -- submit button.
        if newState == kGameStateSubmittingWord then
            selection:hide()
            submitButton:setHighlighted()

        -- Otherwise we want to revert those changes.
        elseif newState == kGameStateEnteringWord then
            selection:moveTo(game:getCurrentRow(), game:getCurrentPosition())
            submitButton:setHighlighted(false)
        end
    end

    -- If the word was not in the list, display a modal informing the player.
    game.listeners[kEventEnteredWordNotInList] = function()
        modal:displayMessageForDuration("I don't know that word.", 2000)
    end

    game.listeners[kEventGameWon] = function()
        modal:displayMessageForDuration("Splendid!", 2000)
    end

    game.listeners[kEventGameLost] = function()
        modal:displayMessageForDuration("Bad luck! The word was \"" .. word .. "\".", 20000)
    end
end

-- Handles all input based on current game state.
local function handleInput()
    -- Input handlers for when the player is entering a word...
    if game.state == kGameStateEnteringWord then
        local change, acceleratedChange = playdate.getCrankChange()

        -- Handle changing letters by cranking if the user has moved the crank.
        if acceleratedChange ~= 0 then
            game:handleCranking(acceleratedChange)

        -- Handle changing letters by pressing up or down
        elseif playdate.buttonJustPressed(playdate.kButtonUp) then
            game:moveLetter(-1)

        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            game:moveLetter(1)

        -- Left/B are used to move back to the previous square.
        elseif
            playdate.buttonJustPressed(playdate.kButtonLeft)
            or playdate.buttonJustPressed(playdate.kButtonB)
        then
            if game:getCurrentPosition() > 1 then
                game:movePosition(-1)
                selection:moveTo(game:getCurrentRow(), game:getCurrentPosition())
            end

        -- Right/A are used to enter a letter and advance to the next square.
        elseif
            playdate.buttonJustPressed(playdate.kButtonRight)
            or playdate.buttonJustPressed(playdate.kButtonA)
        then
            if game:getCurrentPosition() < 5 then
                game:movePosition(1)
                selection:moveTo(game:getCurrentRow(), game:getCurrentPosition())
            else
                -- If we go right off the edge, move into submit mode.
                game:transitionTo(kGameStateSubmittingWord)
            end
        end

        return
    end

    -- In submit mode we are focussed on the submit button. We can only move back out of submit
    -- mode, or confirm our submission.
    if game.state == kGameStateSubmittingWord then
        if
            playdate.buttonJustPressed(playdate.kButtonLeft)
            or playdate.buttonJustPressed(playdate.kButtonB)
        then
            game:transitionTo(kGameStateEnteringWord)

        elseif
            playdate.buttonJustPressed(playdate.kButtonRight)
            or playdate.buttonJustPressed(playdate.kButtonA)
        then
            game:transitionTo(kGameStateCheckingEntry)
        end
    end
end

registerEvents()

function playdate.update()
    -- We do not process input for the game when a modal is displaying.
    if not modal:isDisplaying() then
        -- Check to see if we're crankin' or pressing any buttons, and handle accordingly.
        handleInput()
    end

    -- Update pieces so any animations etc. continue to run.
    game:updatePieces()

    gfx.sprite.update()
    playdate.timer.updateTimers()
end
