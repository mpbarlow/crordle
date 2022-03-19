import "support"

local pieceStates <const> = constants.pieceStates
local wordStates <const> = constants.wordStates

function checkEntry(pieces, correctWord, wordList)
    local results = {
        state = nil,
        pieces = {}
    }

    local enteredWord = ""

    -- Get the entered word
    for position = 1, #pieces do
        enteredWord = enteredWord .. string.lower(pieces[position]:getLetter())
    end

    -- Check if the word is in our list.
    if table.indexOfElement(wordList, enteredWord) == nil then
        -- If it's not, we can exit immediately.
        results.state = wordStates.kWordNotInList

        return results
    end

    -- If the word is valid, check each piece to see which state it should be placed into.
    for position = 1, #pieces do
        local targetLetter = string.sub(correctWord, position, position)
        local enteredLetter = string.sub(enteredWord, position, position)

        if targetLetter == enteredLetter then
            results.pieces[position] = pieceStates.kPieceCorrect
        elseif string.find(correctWord, enteredLetter) ~= nil then
            results.pieces[position] = pieceStates.kPieceWrongLocation
        else
            results.pieces[position] = pieceStates.kPieceIncorrect
        end
    end

    -- Set our overall word state based on whether the whole word matches or not.
    if enteredWord == correctWord then
        results.state = wordStates.kWordCorrect
    else
        results.state = wordStates.kWordIncorrect
    end

    return results
end
