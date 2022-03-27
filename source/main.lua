import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "support"
import "checkEntry"

import "Piece"
import "Selection"

local gfx <const> = playdate.graphics

local gameStates <const> = constants.gameStates
local wordStates <const> = constants.wordStates

local wordList <const> = import "words"
local word = "hello"

local boardOrigin <const> = {x = 10, y = 10}
local pieceSize <const> = {width = 30, height = 30}
local pieceMargin <const> = 5

-- The number of milliseconds to wait between checking each letter when submitting a word.
local checkDuration <const> = 500

local letters <const> = 5
local guesses <const> = 6

local submitButtonBounds <const> = playdate.geometry.rect.new(215, 100, 150, 40)
local submitButtonSprite <const> = gfx.sprite.new()

local board <const> = {}
local activePiece = {row = 1, position = 1}
local gameState = gameStates.kWordEntry

local wordCheckResults = nil

-- Perform the initial set up to configure the game board and UI.
local function setUpGame()
    -- Build the board as a 5x6 grid of Pieces.
    for row = 1, guesses do
        board[row] = {}

        for position = 1, letters do
            local x = ((position - 1) * pieceSize.width) + ((position - 1) * pieceMargin) + boardOrigin.x
            local y = ((row - 1) * pieceSize.height) + ((row - 1) * pieceMargin) + boardOrigin.y

            board[row][position] = Piece({x = x, y = y}, pieceSize)
        end
    end

    -- Configure how the submit button draws itself.
    function submitButtonSprite:draw(x, y, width, height)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(1)

        -- When in entry mode, draw the "unselected" state, i.e. black text on an outline button
        if gameState == gameStates.kWordEntry then
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

            -- Fill the background in
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(0, 0, self.width, self.height, 15)

            -- Draw outline
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRoundRect(0, 0, self.width, self.height, 15)

        -- Otherwise fill the button and draw white text.
        elseif gameState == gameStates.kWordSubmit then
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

    local dotPattern <const> = {
        tonumber('11111111', 2),
        tonumber('11111111', 2),
        tonumber('11111111', 2),
        tonumber('11101111', 2),
        tonumber('11111111', 2),
        tonumber('11111111', 2),
        tonumber('11111111', 2),
        tonumber('11111111', 2),
    }

    gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
        gfx.setClipRect(x, y, width, height)
        gfx.setPattern(dotPattern)
        gfx.fillRect(x, y, width, height)
        gfx.clearClipRect()
    end)
end

setUpGame()

local selection = Selection(boardOrigin, pieceSize, pieceMargin)
selection:moveTo(activePiece.row, activePiece.position)

-- Handle game state transitions.
local function moveToState(newState)
    if newState == gameStates.kWordEntry then
        selection:moveTo(activePiece.row, activePiece.position)
        submitButtonSprite:markDirty()

    elseif newState == gameStates.kWordSubmit then
        selection:setHidden()
        submitButtonSprite:markDirty()

    elseif newState == gameStates.kCheckingEntry then
        wordCheckResults = checkEntry(board[activePiece.row], word, wordList)
    end

    gameState = newState
end

local function displayModal(message, durationMs, returnState)
    -- Better as assertion?
    if gameState == gameStates.kDisplayingMessage then
        return
    end

    gameState = gameStates.kDisplayingMessage

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
        moveToState(returnState)
    end)
end

-- Handles all input based on current game state.
local function handleInput()
    -- Input handlers for when the player is entering a word
    if gameState == gameStates.kWordEntry then
        local change, acceleratedChange = playdate.getCrankChange()

        -- Handle changing letters by cranking if the user has moved the crank.
        if acceleratedChange ~= 0 then
            board[activePiece.row][activePiece.position]:handleCranking(acceleratedChange)

        -- Handle changing letters by pressing up or down
        elseif playdate.buttonJustPressed(playdate.kButtonUp) then
            board[activePiece.row][activePiece.position]:moveLetter(-1)

        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            board[activePiece.row][activePiece.position]:moveLetter(1)

        -- Left/B are used to move back to the previous square.
        elseif
            playdate.buttonJustPressed(playdate.kButtonLeft)
            or playdate.buttonJustPressed(playdate.kButtonB)
        then
            if activePiece.position > 1 then
                activePiece.position -= 1
                selection:moveTo(activePiece.row, activePiece.position)
            end

        -- Right/A are used to enter a letter and advance to the next square.
        elseif
            playdate.buttonJustPressed(playdate.kButtonRight)
            or playdate.buttonJustPressed(playdate.kButtonA)
        then
            if activePiece.position < 5 then
                activePiece.position += 1
                selection:moveTo(activePiece.row, activePiece.position)
            else
                -- If we go right off the edge, move into submit mode.
                moveToState(gameStates.kWordSubmit)
            end
        end

        return
    end

    -- In submit mode we are focussed on the submit button. We can only move back out of submit
    -- mode, or confirm our submission.
    if gameState == gameStates.kWordSubmit then
        if
            playdate.buttonJustPressed(playdate.kButtonLeft)
            or playdate.buttonJustPressed(playdate.kButtonB)
        then
            moveToState(gameStates.kWordEntry)

        elseif
            playdate.buttonJustPressed(playdate.kButtonRight)
            or playdate.buttonJustPressed(playdate.kButtonA)
        then
            moveToState(gameStates.kCheckingEntry)
        end
    end
end

local function handleGameWon()
    displayModal("Splendid!", 5000, gameStates.kGameWon)
end

local function handleGameOver()
    displayModal("Bad luck!", 5000, gameStates.kGameLost)
end

-- React to results of a word that was just entered.
local function handleWordCheck()
    -- If the word was not even in our list, move back to entry mode.
    if wordCheckResults.state == wordStates.kWordNotInList then
        displayModal("Word not in list.", 2000, gameStates.kWordEntry)

    else
        -- Set each piece state one second apart, to give the appearance of checking the result
        -- letter by letter.
        for position = 1, letters do
            local piece = board[activePiece.row][position]
            local state = wordCheckResults.pieces[position]

            playdate.timer.performAfterDelay((position - 1) * checkDuration, function ()
                piece:setPieceState(state)
            end)
        end

        local wordState <const> = wordCheckResults.state

        -- After all the pieces have animated, move to the next row and reset back into word entry
        -- mode. Waiting an extra half beat just feels better for some reason.
        playdate.timer.performAfterDelay(
            (letters * checkDuration) + (checkDuration / 2),
            function ()
                if wordState == wordStates.kWordCorrect then
                    handleGameWon()
                    return
                end

                if activePiece.row == guesses then
                    handleGameOver()
                    return
                end

                activePiece.row += 1
                activePiece.position = 1

                moveToState(gameStates.kWordEntry)
            end
        )
    end
end

local function updatePieceAt(row, position)
    local pieceShouldBeInPlay = row < activePiece.row or position <= activePiece.position

    -- When first adding a piece to play, set its initial letter to the last selected letter rather
    -- than making the player go from "A" every time.
    if position > 1 and not board[row][position].inPlay and pieceShouldBeInPlay then
        board[row][position]:setLetter(board[row][position - 1]:getLetter())
    end

    board[row][position].inPlay = pieceShouldBeInPlay
    board[row][position]:update()
end

function playdate.update()
    -- Check to see if we're crankin' or pressing any buttons, and handle accordingly.
    handleInput()

    -- If we've got results from an entered word...
    if wordCheckResults ~= nil then
        -- ...handle them accordingly...
        handleWordCheck()

        -- ...then unset them so we don't handle them multiple times.
        wordCheckResults = nil
    end

    -- Update the pieces in play.
    for row = 1, activePiece.row do
        for position = 1, letters do
            updatePieceAt(row, position)
        end
    end

    gfx.sprite.update()
    playdate.timer.updateTimers()
    playdate.drawFPS(380, 225)
end
