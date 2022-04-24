import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

import "support"
import "Game"
import "Selection"
import "SubmitButton"
import "Modal"

math.randomseed(playdate.getSecondsSinceEpoch())

local gfx <const> = playdate.graphics
local logo <const> = playdate.graphics.image.new("images/Crordle logo")

-- An 8x8 pattern that has a white background with a single block dot (approximately) in the center
local dotPattern <const> = {0xFF, 0xFF, 0xFF, 0xEF, 0xFF, 0xFF, 0xFF, 0xFF}
local wordList <const> = import "words"

-- UI state determines where we direct our inputs, e.g. into the game or into "UI-y" stuff like
-- dismissing a modal.
local uiState = kUIStatePlayingGame

-- Objects for UI elements in-game
local selection <const> = Selection(boardOrigin, pieceSize, pieceMargin)
local submitButton <const> = SubmitButton()
local modal <const> = Modal()

-- Tracks the state for the current game.
local game

-- Draw our background pattern and the Crordle logo
gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
    gfx.setClipRect(x, y, width, height)

    doInGraphicsContext(function ()
        -- Background pattern
        gfx.setPattern(dotPattern)
        gfx.fillRect(x, y, width, height)

        -- Logo
        logo:draw(210, 25)

        -- Controls
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(200, 155, 180, 65, 5)

        gfx.setColor(gfx.kColorBlack)
        gfx.drawRoundRect(200, 155, 180, 65, 5)

        fonts.small:drawTextAligned("Crank/Up/Down: Choose", 290, 160, kTextAlignment.center)
        fonts.small:drawTextAligned("Ⓐ/Right: Next", 290, 180, kTextAlignment.center)
        fonts.small:drawTextAligned("Ⓑ/Left: Previous", 290, 200, kTextAlignment.center)
    end)

    gfx.clearClipRect()
end)

-- To avoid having to implement a system where we check the game state each update and ensure we
-- only react to each change once, we instead have a nice event system where the game will call
-- our functions in response to various state changes.
local function registerEventHandlers()
    game:registerEventHandler(kEventGameStateDidTransition, function(game, newState)
        -- If we move into submission mode, we want to hide the selection ring and highlight the
        -- submit button.
        if newState == kGameStateSubmittingWord then
            selection:hide()
            submitButton:setHighlighted()

        -- Otherwise we want to revert those changes.
        elseif newState == kGameStateEnteringWord then
            selection:moveTo(game:getCurrentRow(), game:getCurrentPosition())
            submitButton:setHighlighted(false)

        elseif newState == kGameStateWon then
            uiState = kUIStateDisplayingModal
            modal:displayMessage("Splendid!", "New game")

        elseif newState == kGameStateLost then
            uiState = kUIStateDisplayingModal
            modal:displayMessage("Bad luck! The word was \"" .. game.word .. "\".", "Try again")
        end
    end)

    -- If the word was not in the list, display a modal informing the player.
    game:registerEventHandler(kEventEnteredWordNotInList, function()
        uiState = kUIStateDisplayingModal
        modal:displayMessage("That's not in the word list!")
    end)
end

-- Start a new game
local function resetGame()
    -- Before we kill the old game we need to remove all the piece sprites from the display list
    -- so they don't keep drawing underneath our new sprites.
    if game ~= nil then
        game:tearDown()
    end

    -- Create a new game, casting any old game unto ye cruel garbage collector
    game = Game(wordList)
    registerEventHandlers()

    -- Reset UI
    selection:moveTo(game:getCurrentRow(), game:getCurrentPosition())
    submitButton:setHighlighted(false)
end

-- Handles all input based on current game state.
local function handleInput()
    -- If we're displaying a modal, direct into into that instead of the game.
    if uiState == kUIStateDisplayingModal then
        if
            playdate.buttonJustPressed(playdate.kButtonA)
            or playdate.buttonJustPressed(playdate.kButtonRight)
        then
            -- If we've won or lost, start a new game
            if game.state == kGameStateWon or game.state == kGameStateLost then
                resetGame()
            end

            modal:dismiss()
            uiState = kUIStatePlayingGame
        end

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

resetGame()

local showingCrankAlert = false
local crankAlertTimerExpired = false

-- If the player starts the game with the crank docked, show the "Use the crank!" popup for 2.5s
if playdate.isCrankDocked() then
    playdate.ui.crankIndicator:start()
    showingCrankAlert = true
    playdate.timer.performAfterDelay(2500, function() crankAlertTimerExpired = true end)
end

function playdate.update()
    -- Check to see if we're crankin' or pressing any buttons, and handle accordingly.
    handleInput()

    -- Update pieces so any animations etc. continue to run.
    game:updatePieces()

    gfx.sprite.update()

    if showingCrankAlert and not crankAlertTimerExpired then
        playdate.ui.crankIndicator:update()
    end

    playdate.timer.updateTimers()
end
