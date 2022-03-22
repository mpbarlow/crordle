import "support"

local pieceStates <const> = constants.pieceStates
local wordStates <const> = constants.wordStates

-- Create a map tracking the frequency of each letter in the provided word.
local function makeFrequencyMap(word)
    local map = {}

    for l = 1, #word do
        local letter = word:sub(l, l)
        map[letter] = (map[letter] or 0) + 1
    end

    return map
end

function checkEntry(pieces, correctWord, wordList)
    local results = {
        state = nil,
        pieces = {}
    }

    local enteredWord = ""

    -- Get the entered word
    for position = 1, #pieces do
        enteredWord = enteredWord .. pieces[position]:getLetter():lower()
    end

    -- Check if the word is in our list.
    if table.indexOfElement(wordList, enteredWord) == nil then
        -- If it's not, we can exit immediately.
        results.state = wordStates.kWordNotInList

        return results
    end

    -- Map how frequently each letter appears in each word. This will allow us to correctly
    -- implement the "wrong location logic.
    local correctWordMap = makeFrequencyMap(correctWord)
    local enteredWordMap = makeFrequencyMap(enteredWord)

    -- If the word is valid, check each piece to see which state it should be placed into.
    for position = 1, #pieces do
        local targetLetter = correctWord:sub(position, position)
        local enteredLetter = enteredWord:sub(position, position)

        if targetLetter == enteredLetter then
            results.pieces[position] = pieceStates.kPieceCorrect

        -- A piece should only be marked as in the wrong location if there are still instances of
        -- that letter that have not been identified.
        -- e.g. if correctWord is HELLO and enteredWord is BEEFY, the second E in BEEFY should be
        -- marked incorrect, not wrong location.
        elseif
            correctWord:find(enteredLetter) ~= nil
            and enteredWordMap[enteredLetter] <= (correctWordMap[enteredLetter] or 0)
        then
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
