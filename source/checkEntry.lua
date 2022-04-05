import "support"

-- Mark letter positions as correct if the letter at that position matches the letter at that
-- position of the correct word.
local function markCorrectLetters(map, enteredWord, correctWord)
    for i = 1, #enteredWord do
        if enteredWord:sub(i, i) == correctWord:sub(i, i) then
            map[i] = kLetterStateCorrect
        end
    end
end

-- Mark letter positions as wrong location if the letter at that position is present in the letters
-- of the correct word in positions that have not yet been classified.
local function markWrongLocationLetters(map, enteredWord, correctWord)
    for i = 1, #enteredWord do
        if map[i] == nil then
            local remainingLetters <const> = correctWord:filter(function (_, index)
                return map[index] == nil
            end)

            if remainingLetters:find(enteredWord:sub(i, i)) ~= nil then
                map[i] = kLetterStateWrongLocation
            end
        end
    end
end

-- Finally, anything left unmarked must be incorrect
local function markIncorrectLetters(map, enteredWord, correctWord)
    for i = 1, #enteredWord do
        if map[i] == nil then
            map[i] = kLetterStateIncorrect
        end
    end
end

function checkEntry(enteredWord, correctWord, wordList)
    local results = {
        state = nil,
        letters = {}
    }

    -- Check if the word is in our list.
    if table.indexOfElement(wordList, enteredWord) == nil then
        -- If it's not, we can exit immediately.
        results.state = kWordStateNotInList

        return results
    end

    -- We run three passes on the entered word...

    -- The first marks all letters that are in the correct place.
    markCorrectLetters(results.letters, enteredWord, correctWord)

    -- The second marks all letters that exist in correctWord, but that are not in the right place.
    -- This is a rolling process, so if we have two As in the wrong place but only one A in the
    -- correct word, the second A will be marked as incorrect as to not mislead the player.
    markWrongLocationLetters(results.letters, enteredWord, correctWord)

    -- Finally, any letters which have not yet been checked must be incorrect.
    markIncorrectLetters(results.letters, enteredWord, correctWord)

    -- Set our overall word state based on whether the whole word matches or not.
    if enteredWord == correctWord then
        results.state = kWordStateCorrect
    else
        results.state = kWordStateIncorrect
    end

    return results
end
