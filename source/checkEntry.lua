-- checkEntry.lua
-- Provides the function that checks player word entries against the correct word and the acceptable
-- word list.

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
-- of the correct word, in positions that have not yet been classified.
local function markWrongLocationLetters(map, enteredWord, correctWord)
    -- Create an array of the letters in the target word. We do this so we can remove matched
    -- letters without affecting the indexing.
    local correctWordLetters <const> = {}

    for i = 1, #correctWord do
        correctWordLetters[i] = correctWord:sub(i, i)
    end

    -- Iterate through the player's entry...
    for i = 1, #enteredWord do
        -- If the letter has already been classified (i.e. it's correct), do not consider it.
        if map[i] == nil then
            -- Check to see if the letter is present in the correct word
            if table.indexOfElement(correctWordLetters, enteredWord:sub(i, i)) ~= nil then
                -- If it is, mark the entered letter as wrong location and remove the letter from
                -- the correct word map, so it can't be double-matched.
                map[i] = kLetterStateWrongLocation
                correctWordLetters[i] = nil
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

-- Given the player's entered word, the target word, and the acceptable word list, return a table
-- containing the overall match state, and the state of each individual letter.
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
