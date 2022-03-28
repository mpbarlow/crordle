import "CoreLibs/object"
import "support"
import "Piece"
import "checkEntry"

local gfx <const> = playdate.graphics

local gameStates <const> = constants.gameStates
local gameEvents <const> = constants.gameEvents
local wordStates <const> = constants.wordStates

local wordList <const> = import "words"

-- The number of milliseconds to wait between checking each letter when submitting a word.
local checkDuration <const> = 500

local function createBoard()
    local board = {}

    -- Build the board as a letters x guesses grid of Pieces.
    for row = 1, guesses do
        board[row] = {}

        for position = 1, letters do
            local x = ((position - 1) * pieceSize.width) + ((position - 1) * pieceMargin) + boardOrigin.x
            local y = ((row - 1) * pieceSize.height) + ((row - 1) * pieceMargin) + boardOrigin.y

            board[row][position] = Piece({x = x, y = y}, pieceSize)
        end
    end

    return board
end

class('Game', {
    listeners = {
        [gameEvents.kStateTransitioned] = function () end,
        [gameEvents.kGameWon] = function () end,
        [gameEvents.kGameLost] = function () end,
    },
    modalHandler = nil,
    state = gameStates.kWordEntry
}).extends()

function Game:init(word)
    local board <const> = createBoard()

    local activeRow = 1
    local activePosition = 1

    local wordCheckResults = nil

    local function row(self)
        return activeRow
    end

    local function position(self)
        return activePosition
    end

    local function transitionTo(self, newState)
        if newState == gameStates.kCheckingEntry then
            wordCheckResults = checkEntry(board[activeRow], word, wordList)
        end

        self.state = newState
        self.listeners[gameEvents.kStateTransitioned](self, newState)
    end

    local function handleCranking(self, acceleratedChange)
        board[activeRow][activePosition]:handleCranking(acceleratedChange)
    end

    local function moveLetter(self, steps)
        board[activeRow][activePosition]:moveLetter(steps)
    end

    local function movePosition(self, steps)
        activePosition += steps
    end

    local function updatePieceAt(row, position)
        local pieceShouldBeInPlay = row < activeRow or position <= activePosition

        -- When first adding a piece to play, set its initial letter to the last selected letter rather
        -- than making the player go from "A" every time.
        if position > 1 and not board[row][position].inPlay and pieceShouldBeInPlay then
            board[row][position]:setLetter(board[row][position - 1]:getLetter())
        end

        board[row][position].inPlay = pieceShouldBeInPlay
        board[row][position]:update()
    end

    -- React to results of a word that was just entered.
    local function handleWordCheck()
        -- If the word was not even in our list, move back to entry mode.
        if wordCheckResults.state == wordStates.kWordNotInList then
            self.listeners[gameEvents.kWordNotInList](self)
            self:transitionTo(gameStates.kWordEntry)

        else
            -- Set each piece state one second apart, to give the appearance of checking the result
            -- letter by letter.
            for position = 1, letters do
                local piece = board[activeRow][position]
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
                        self.listeners[gameEvents.kGameWon](self)
                        self:transitionTo(gameStates.kGameWon)

                        return
                    end

                    if activeRow == guesses then
                        self.listeners[gameEvents.kGameLost](self)
                        self:transitionTo(gameStates.kGameLost)

                        return
                    end

                    activeRow += 1
                    activePosition = 1

                    self:transitionTo(gameStates.kWordEntry)
                end
            )
        end
    end

    local function update(self)
        -- If we've got results from an entered word...
        if wordCheckResults ~= nil then
            -- ...handle them accordingly...
            handleWordCheck()

            -- ...then unset them so we don't handle them multiple times.
            wordCheckResults = nil
        end

        -- Update the pieces in play.
        for row = 1, activeRow do
            for position = 1, letters do
                updatePieceAt(row, position)
            end
        end
    end

    self.row = row
    self.position = position
    self.transitionTo = transitionTo
    self.handleCranking = handleCranking
    self.moveLetter = moveLetter
    self.movePosition = movePosition
    self.update = update
end
