import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "support"
import "Game"
import "Selection"

local gfx <const> = playdate.graphics

local word = "hello"
local displayingModal = false

local submitButtonBounds <const> = playdate.geometry.rect.new(215, 100, 150, 40)
local submitButtonSprite <const> = gfx.sprite.new()
local selection = Selection(boardOrigin, pieceSize, pieceMargin)

local dotPattern <const> = {0xFF, 0xFF, 0xFF, 0xEF, 0xFF, 0xFF, 0xFF, 0xFF}

local game = Game(word)

-- Perform the initial set up to configure the game board and UI.
local function setUpSprites()
    selection:moveTo(game:getCurrentRow(), game:getCurrentPosition())

    -- Configure how the submit button draws itself.
    function submitButtonSprite:draw(x, y, width, height)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(1)

        -- When in entry mode, draw the "unselected" state, i.e. black text on an outline button
        if game.state == kGameStateEnteringWord then
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

            -- Fill the background in
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(0, 0, self.width, self.height, 15)

            -- Draw outline
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRoundRect(0, 0, self.width, self.height, 15)

        -- Otherwise fill the button and draw white text.
        elseif game.state == kGameStateSubmittingWord then
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.fillRoundRect(0, 0, self.width, self.height, 15)
        end

        gfx.drawTextAligned(
            "*Submit*",
            self.width / 2,
            (self.height / 2) - 8,
            kTextAlignment.center
        )
    end

    submitButtonSprite:setBounds(submitButtonBounds)
    submitButtonSprite:add()

    gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
        gfx.setClipRect(x, y, width, height)
        gfx.setPattern(dotPattern)
        gfx.fillRect(x, y, width, height)
        gfx.clearClipRect()
    end)
end

local function displayModal(message, durationMs)
    if displayingModal then
        return
    end

    displayingModal = true

    local sprite = gfx.sprite.new()

    function sprite:draw(x, y, width, height)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(0, 0, self.width, self.height, 10)

        gfx.setColor(gfx.kColorBlack)
        gfx.drawRoundRect(0, 0, self.width, self.height, 10)

        gfx.drawTextAligned(message, self.width / 2, (self.height / 2) - 8, kTextAlignment.center)
    end

    sprite:setBounds(50, 70, 300, 100)
    sprite:setZIndex(10)

    sprite:add()

    playdate.timer.performAfterDelay(durationMs, function ()
        sprite:remove()
        displayingModal = false
    end)
end

-- To avoid having to implement a "latch" system where the check the game state ourselves and ensure
-- we only react to each change once, we instead have a nice event system where the game will call
-- our functions in response to various state changes.
local function registerEvents()
    game.listeners[kEventGameStateDidTransition] = function(game, newState)
        -- If we move into submission mode, we want to hide the selection ring and highlight the
        -- submit button.
        if newState == kGameStateSubmittingWord then
            selection:setHidden()
            submitButtonSprite:markDirty()

        -- Otherwise we want to revert those changes.
        elseif newState == kGameStateEnteringWord then
            selection:moveTo(game:getCurrentRow(), game:getCurrentPosition())
            submitButtonSprite:markDirty()
        end
    end

    -- If the word was not in the list, display a modal informing the player.
    game.listeners[kEventEnteredWordNotInList] = function(game)
        displayModal("Word not in list.", 2000)
    end
end

setUpSprites()
registerEvents()

-- Handles all input based on current game state.
local function handleInput()
    -- We do not process input for the game when a modal is displaying.
    if displayingModal then
        return
    end

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

function playdate.update()
    -- Check to see if we're crankin' or pressing any buttons, and handle accordingly.
    handleInput()

    -- Update pieces so any animations etc. continue to run.
    game:updatePieces()

    gfx.sprite.update()
    playdate.timer.updateTimers()
end
