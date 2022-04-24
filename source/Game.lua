-- Game.lua
-- A class encapsulating the logic of the game itself. Instantiates the board and updates pieces
-- as needed. Works like a state machine; the game is always in exactly one state and can transition
-- to another in response to player action.

import "CoreLibs/object"
import "support"
import "checkEntry"
import "Piece"

local gfx <const> = playdate.graphics

-- The number of milliseconds to wait between checking each letter when submitting a word.
local checkDuration <const> = 400

-- Build the board as a letterCount x guessCount grid of Pieces.
local function createBoard()
    local board = {}

    for row = 1, guessCount do
        board[row] = {}

        for position = 1, letterCount do
            local x = ((position - 1) * pieceSize.width) + ((position - 1) * pieceMargin) + boardOrigin.x
            local y = ((row - 1) * pieceSize.height) + ((row - 1) * pieceMargin) + boardOrigin.y

            board[row][position] = Piece({x = x, y = y}, pieceSize)
        end
    end

    return board
end

class('Game', {
    -- We begin the game entering a word.
    state = kGameStateEnteringWord
}).extends()

function Game:init(solutionList, wordList, userData)
    Game.super.init(self)

    -- Set the word for the game at random.
    self.word = table.randomElement(solutionList)

    if playdate.isSimulator then
        print(self.word)
    end

    -- Set default event handlers so we don't have to check if they're defined before firing them.
    local eventHandlers = {
        [kEventGameStateDidTransition] = function () end,
        [kEventEnteredWordNotInList] = function () end,
    }

    -- Register a handler for a particular game event.
    local function registerEventHandler(self, event, handler)
        eventHandlers[event] = handler
    end

    local board <const> = createBoard()

    local currentRow = 1
    local currentPosition = 1

    local function getCurrentRow(self)
        return currentRow
    end

    local function getCurrentPosition(self)
        return currentPosition
    end

    -- Update game and piece state based on the contents of wordCheckResults, the object returned
    -- by checkEntry().
    local function handleEntryCheck(wordCheckResults)
        -- If the word was not in the list, emit the appropriate event and move back to entry mode.
        if wordCheckResults.state == kWordStateNotInList then
            eventHandlers[kEventEnteredWordNotInList](self)
            self:transitionTo(kGameStateEnteringWord)

        -- Otherwise, update each piece's state to match the results. We update each piece a
        -- certain time after the last, to give the appearance of checking letter by letter.
        else
            for position = 1, letterCount do
                local piece = board[currentRow][position]
                local state = wordCheckResults.letters[position]

                playdate.timer.performAfterDelay((position - 1) * checkDuration, function ()
                    piece:setPieceState(state)
                end)
            end

            -- After all the pieces have animated, move to the next row and reset back into word
            -- entry mode. Waiting an extra half beat just feels better for some reason.
            playdate.timer.performAfterDelay(
                (letterCount * checkDuration) + (checkDuration / 2),
                function ()
                    -- If the word was correct, the player won.
                    if wordCheckResults.state == kWordStateCorrect then
                        self:transitionTo(kGameStateWon)

                        return
                    end

                    -- If it wasn't correct and the player used all their guesses, they lost.
                    if currentRow == guessCount then
                        self:transitionTo(kGameStateLost)

                        return
                    end

                    -- Otherwise move onto the next row and switch back to word entry mode.
                    currentRow += 1
                    currentPosition = 1

                    self:transitionTo(kGameStateEnteringWord)
                end
            )
        end
    end

    -- Returns the entered word on the current row of the board (in lowercase).
    local function getEnteredWord()
        local word = ""

        for i = 1, letterCount do
            word = word .. board[currentRow][i]:getLetter():lower()
        end

        return word
    end

    -- Perform a state transition to newState.
    local function transitionTo(self, newState)
        -- Update our state and call the event listener for a state transition to allow stuff
        -- outside of the core game logic to react (e.g. displaying a modal).
        self.state = newState
        eventHandlers[kEventGameStateDidTransition](self, newState)

        -- If we've moved into the entry check state, check the input and update the game and piece
        -- state accordingly.
        if newState == kGameStateCheckingEntry then
            handleEntryCheck(checkEntry(getEnteredWord(), self.word, wordList))
        end
    end

    -- Forward crank input to the active piece.
    local function handleCranking(self, acceleratedChange)
        board[currentRow][currentPosition]:handleCranking(acceleratedChange)
    end

    -- Tell the active piece to move the letter selection by `steps` letters.
    local function moveLetter(self, steps)
        board[currentRow][currentPosition]:moveLetter(steps)
    end

    -- Move the active piece selection by `steps` pieces.
    local function movePosition(self, steps)
        currentPosition += steps
    end

    -- Update the board piece at the given (row, position) co-ordinate.
    local function updatePieceAt(row, position)
        local pieceShouldBeInPlay = board[row][position].inPlay
            or row < currentRow
            or position <= currentPosition

        -- When first adding a piece to play, set its initial letter to the last selected letter,
        -- rather than making the player go from "A" every time -- unless they would prefer to and
        -- have changed the setting.
        if
            not userData.startFromA
            and position > 1
            and not board[row][position].inPlay
            and pieceShouldBeInPlay
        then
            board[row][position]:setLetter(board[row][position - 1]:getLetter())
        end

        -- Mark newly selected pieces as "in play"
        board[row][position].inPlay = pieceShouldBeInPlay
        board[row][position]:update()
    end

    -- Update the pieces in play or that have previously been in play.
    local function updatePieces(self)
        for row = 1, currentRow do
            for position = 1, letterCount do
                updatePieceAt(row, position)
            end
        end
    end

    -- Destroy the old sprites in preparation for a new game.
    local function tearDown()
        for row = 1, guessCount do
            for position = 1, letterCount do
                board[row][position]:tearDown()
            end
        end
    end

    -- Bind public methods
    self.registerEventHandler = registerEventHandler
    self.getCurrentRow = getCurrentRow
    self.getCurrentPosition = getCurrentPosition
    self.transitionTo = transitionTo
    self.handleCranking = handleCranking
    self.moveLetter = moveLetter
    self.movePosition = movePosition
    self.updatePieces = updatePieces
    self.tearDown = tearDown
end
