import "CoreLibs/object"
import "CoreLibs/timer"
import "support"

local pieceStates <const> = constants.pieceStates

class('Checker', {
    done = false
}).extends()

function Checker:init(pieces, word)
    Checker.super.init(self)

    for position = 1, #pieces do
        local targetLetter = string.sub(word, position, position)
        local enteredLetter = string.lower(pieces[position]:getLetter())

        local function timerCallback()
            if targetLetter == enteredLetter then
                pieces[position]:setPieceState(pieceStates.kPieceCorrect)
            else
                pieces[position]:setPieceState(pieceStates.kPieceIncorrect)
            end
        end

        playdate.timer.performAfterDelay((position - 1) * 1000, timerCallback)
    end

    local function finish()
        self.done = true
    end

    playdate.timer.performAfterDelay(#pieces * 1000, finish)
end
