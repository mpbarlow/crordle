import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "support"
import "Piece"
import "Selection"
import "Checker"

local gfx <const> = playdate.graphics
local gameStates <const> = constants.gameStates

local wordList <const> = import "words"
local word = "hello"

local boardOrigin <const> = {x = 10, y = 10}
local pieceSize <const>   = {width = 30, height = 30}
local pieceMargin <const> = 5

local submitButtonBounds <const> = playdate.geometry.rect.new(200, 100, 150, 40)
local submitButtonSprite <const> = gfx.sprite.new()

local board <const> = {}
local activePiece   = {row = 1, position = 1}
local gameState     = gameStates.kWordEntry

local wordChecker = nil

-- Perform the initial set up to configure the game board and UI.
local function setUpGame()
    -- Build the board as a 5x6 grid of Pieces.
    for row = 1, 6 do
        board[row] = {}

        for position = 1, 5 do
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
end

setUpGame()

local selection = Selection(boardOrigin, pieceSize, pieceMargin)
selection:moveTo(activePiece.row, activePiece.position)

local function moveToState(newState)
    if newState == gameStates.kWordEntry then
        selection:moveTo(activePiece.row, activePiece.position)
        submitButtonSprite:markDirty()

    elseif newState == gameStates.kWordSubmit then
        selection:setHidden()
        submitButtonSprite:markDirty()

    elseif newState == gameStates.kCheckingEntry then
        wordChecker = Checker(board[activePiece.row], word)
    end

    gameState = newState
end

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

function playdate.update()
    handleInput()

    if wordChecker ~= nil and wordChecker.done then
        activePiece.row += 1
        activePiece.position = 1

        moveToState(gameStates.kWordEntry)

        wordChecker = nil
    end

    for row = 1, activePiece.row do
        for position = 1, 5 do
            board[row][position].inPlay = row < activePiece.row or position <= activePiece.position
            board[row][position]:update()
        end
    end

    gfx.sprite.update()

    playdate.timer.updateTimers()
    playdate.drawFPS(380, 225)
end
