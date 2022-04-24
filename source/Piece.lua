-- Piece.lua
-- Piece encapsulates a single letter selection.
-- Rendering is modelled as an endlessly scrolling, wrapping list. The previous, current, and next
-- letters are rendered size.height pixels apart, with the entire thing shifted by offset % height.
-- The current letter seamlessly becomes the last letter (and the next the current) as scrolling
-- occurs, by mapping the offset over the 26 letters.

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/animator"
import "CoreLibs/timer"
import "support"

local gfx <const> = playdate.graphics

local letters <const> = {
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S",
    "T", "U", "V", "W", "X", "Y", "Z"
}

-- A single-pixel wide diagonal stripe pattern to use for letters in the incorrect location.
local diagonalPattern <const> = {
    tonumber("11101111", 2),
    tonumber("11011111", 2),
    tonumber("10111111", 2),
    tonumber("01111111", 2),
    tonumber("11111110", 2),
    tonumber("11111101", 2),
    tonumber("11111011", 2),
    tonumber("11110111", 2),
}

-- How many letters a complete crank should scroll by. Note that this is more of a generic
-- multiplier than a hard value, as we use the accelerated change when handling cranking.
local lettersPerCrank <const> = 3

-- Duration in ms of the flip animation when revealing letter results.
local flipDuration <const> = 400

-- Duration in ms of the animation of a letter snapping into place.
local snapDuration <const> = 250

-- Timeout in ms after cranking stops before a letter snaps into place.
local snapTimeout <const> = 1000

class('Piece', {
    -- Pieces that are not yet in play do not render a letter.
    inPlay = false
}).extends()

function Piece:init(origin, size)
    Piece.super.init(self)

    -- Track the current play state of our piece. Each piece starts unchecked.
    local pieceState = nil

    -- Store the letter index. This is the source of truth for which letter is actually selected in
    -- the piece.
    local index = 1
    local maxIndex <const> = #letters

    -- Stores the scroll offset, from 0 to 26 * size.height. Offset is used for drawing, not the
    -- selection of letters, however during cranking the offset does update the index based on the
    -- closest letter.
    local offset = 0
    local maxOffset <const> = size.height * #letters;

    local sprite = gfx.sprite.new()

    -- Handles animating to a new position when using the buttons or drawing the "flip" when the
    -- player enters a word.
    local offsetAnimator = nil
    local flipAnimator = nil

    -- Tracks how long it has been since cranking stopped. After the timer ends, the display will
    -- "snap" to the nearest letter.
    local snapTimer = nil

    -- Create a new animator from the current offset to the given value.
    local function animateOffsetTo(to)
        -- To correctly handle wrapping at either end, we want to always animate via the shortest
        -- path to the target offset.
        -- e.g. if we are at offset 0 (A) and want to move to offset 750 (Z), we actually want to go
        -- back one letter instead of forward by 25.
        -- To do this we work out the offset to get to the same place in the opposite direction,
        -- and always take whichever path is shortest.
        local oppositeEquivalent

        if to > offset then
            oppositeEquivalent = to - maxOffset
        else
            oppositeEquivalent = maxOffset + to
        end

        if math.abs(oppositeEquivalent - offset) < math.abs(to - offset) then
            to = oppositeEquivalent
        end

        offsetAnimator = gfx.animator.new(snapDuration, offset, to)
    end

    -- Set the offset to an explicit value, wrapping at either end. The wrapping functionality
    -- allows us to not have to worry about whether any animators we use cross a wrap boundary
    -- (e.g. we can animate from 0 to -30 and this function will handle wrapping it for us).
    -- Because offset determines where the letter is drawn, we also mark the sprite as dirty.
    local function setOffset(newOffset)
        if newOffset < 0 then
            newOffset += maxOffset
        elseif newOffset >= maxOffset then
            newOffset -= maxOffset
        end

        offset = newOffset
        sprite:markDirty()
    end

    -- Similar to setOffset, but allow us to set the current letter index instead.
    local function setIndex(newIndex)
        if newIndex < 1 then
            newIndex += maxIndex
        elseif newIndex > maxIndex then
            newIndex -= maxIndex
        end

        index = newIndex
    end

    -- currentRenderIndex is whichever index/letter the top of the piece is currently inside.
    -- However, having scrolled more than half a piece in either direction, we're actually closer
    -- to the next/previous letter. As such, we want to snap to *that* letter, not back to whatever
    -- we were on before.
    local function closestIndexToOffset()
        return math.floor((offset / size.height) + 0.5) + 1
    end

    -- Return which letter index the offset is currently pointing at.
    local function currentRenderIndex()
        return math.floor(offset / size.height) + 1
    end

    -- Return the index of the previous letter, wrapping back round to the last if needed.
    local function previousRenderIndex()
        local currentIndex = currentRenderIndex()

        if currentIndex - 1 <= 0 then
            return #letters
        end

        return currentIndex - 1
    end

    -- Return the index of the next letter, wrapping back round to the first if needed.
    local function nextRenderIndex()
        local currentIndex = currentRenderIndex()

        if currentIndex + 1 > maxIndex then
            return 1
        end

        return currentIndex + 1
    end

    -- Handle `change` degrees of crank rotation.
    local function handleCranking(self, change)
        -- If we're currently animating to a new selection from a button press, cancel it so the
        -- crank takes priority.
        offsetAnimator = nil

        if snapTimer == nil then
            -- This timer will track how long it's been since cranking stopped, so after a brief
            -- pause we can snap the letter into place.
            snapTimer = playdate.timer.new(snapTimeout)
        end

        -- Reset the timer each time the crank moves, so we don't time out while still moving.
        snapTimer:reset()

        -- Update the offset by however much we moved.
        setOffset(offset + ((change * lettersPerCrank * size.height) / 360))

        -- Make sure the index immediately reflects our offset position so that speedy players don't
        -- need to wait for snap animations to finish.
        setIndex(closestIndexToOffset())
    end

    -- Animate to `steps` letters away.
    local function moveLetter(self, steps)
        setIndex(index + steps)
        animateOffsetTo((index - 1) * size.height)
    end

    -- Return the selected letter.
    local function getLetter(self)
        if not self.inPlay then
            return ""
        end

        return letters[index]
    end

    -- Set the a particular letter directly (used for setting the initial letter).
    local function setLetter(self, letter)
        index = table.indexOfElement(letters, string.upper(letter))
        offset = (index - 1) * size.height
    end

    -- When checking an entry each piece is assigned a state based on whether the guess was correct.
    -- We use that to determine how to draw the piece, and animate the transition.
    local function setPieceState(self, newState)
        pieceState = newState
        flipAnimator = gfx.animator.new(flipDuration, -1, 1)
    end

    -- Do anything that needs to run on every frame.
    local function update(self)
        -- If we've configured an animator, get the next value and update our current offset to it.
        if offsetAnimator ~= nil then
            -- If we're already animating something, that means that either a button was pressed,
            -- or our snap timer expired and we're animating it into place. In either case, we no
            -- longer want the timer to be running.
            if snapTimer ~= nil then
                snapTimer:remove()
                snapTimer = nil
            end

            setOffset(offsetAnimator:currentValue())

            if offsetAnimator:ended() then
                offsetAnimator = nil
            end
        -- If we have a complete snapTimer, snap the letter into place.
        elseif snapTimer ~= nil and snapTimer.timeLeft == 0 then
            -- Kill the timer to stop us getting into an infinite loop.
            snapTimer:remove()
            snapTimer = nil

            animateOffsetTo((closestIndexToOffset() - 1) * size.height)
        end

        -- If we have a flip animator, we just need to tell the sprite to update, because it will
        -- read directly from the animator itself as there is no separate state to update.
        if flipAnimator ~= nil then
            sprite:markDirty()

            if flipAnimator:ended() then
                flipAnimator = nil
            end
        end
    end

    -- Remove the sprite in preparation for a new game.
    local function tearDown()
        sprite:remove()
    end

    -- Alias self to allow the sprite draw callback to check if the piece is in play.
    local piece = self

    -- Drawing callback.
    function sprite:draw(x, y, width, height)
        doInGraphicsContext(function ()
            local yOffset = 0
            local height = self.height
            local flipProgress = 0

            if flipAnimator ~= nil then
                flipProgress = flipAnimator:currentValue()

                -- We can simulate flipping by shrinking the height we draw and moving the rectangle
                -- closer to the center at the same time.
                -- We animate from -1 to 1 and then abs it to allow us to do a parabolic animation
                -- using a single animator.
                yOffset = (self.height / 2) - ((self.height / 2) * math.abs(flipProgress))
                height = self.height * math.abs(flipProgress)
            end

            -- Draw the border.
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(0, yOffset, self.width, height)

            -- If the piece is not in play it should not render a letter.
            if not piece.inPlay then
                gfx.setDitherPattern(0.5)
                gfx.fillRect(1, 1, self.width - 2, self.height - 2)

                return
            end

            -- If we're in the first half of a flip animation, animate to an increasingly darker
            -- dither to simulate shading.
            if flipProgress < 0 then
                gfx.setDitherPattern(math.abs(flipProgress))
                gfx.fillRect(1, yOffset + 1, self.width - 2, height - 2)

            -- Otherwise apply shading based on piece state.
            else
                -- If the letter is totally incorrect, fill the piece black and draw white text.
                if pieceState == kLetterStateIncorrect then
                    gfx.fillRect(1, yOffset + 1, self.width - 2, height - 2)
                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

                -- If the letter is in the wrong location, draw diagonal lines
                elseif pieceState == kLetterStateWrongLocation then
                    gfx.setPattern(diagonalPattern)
                    gfx.fillRect(1, yOffset + 1, self.width - 2, height - 2)

                    -- Draw a white circle around the letter so we can still see it.
                    gfx.setColor(gfx.kColorWhite)
                    gfx.fillEllipseInRect(4, yOffset + 4, self.width - 8, math.max(0, height - 8))

                -- Otherwise, fill it white
                else
                    gfx.setColor(gfx.kColorWhite)
                    gfx.fillRect(1, yOffset + 1, self.width - 2, height - 2)
                end
            end

            -- If we're animating a flip we don't want to draw the letter as we'll see it through
            -- the animation.
            if flipAnimator ~= nil then
                return
            end

            -- To keep the draw logic simple, we always draw the current, previous, and next letter,
            -- taking advantage of sprite clipping to only show what should be visible.
            local prevLetter = "*" .. letters[previousRenderIndex()] .. "*"
            local currentLetter = "*" .. letters[currentRenderIndex()] .. "*"
            local nextLetter = "*" .. letters[nextRenderIndex()] .. "*"

            local prevWidth = gfx.getTextSize(prevLetter)
            local currentWidth = gfx.getTextSize(currentLetter)
            local nextWidth = gfx.getTextSize(nextLetter)

            -- getTextSize reports back a height of 20px which I guess is line height rather than
            -- the actual character? 16px seems to work well here.
            local letterHeight = 16

            -- The relative scroll offset within the height of the piece.
            local relativeOffset = offset % self.height

            -- Draw the previous, current, and next letters one piece height apart.
            gfx.drawText(
                prevLetter,
                (self.width / 2) - (prevWidth / 2),
                (self.height / 2) - (letterHeight / 2) - relativeOffset - self.height
            )

            gfx.drawText(
                currentLetter,
                (self.width / 2) - (currentWidth / 2),
                (self.height / 2) - (letterHeight / 2) - relativeOffset
            )

            gfx.drawText(
                nextLetter,
                (self.width / 2) - (nextWidth / 2),
                (self.height / 2) - (letterHeight / 2) - relativeOffset + self.height
            )
        end)
    end

    sprite:setBounds(origin.x, origin.y, size.width, size.height)
    sprite:add()

    -- Bind public methods
    self.handleCranking = handleCranking
    self.moveLetter = moveLetter
    self.getLetter = getLetter
    self.setLetter = setLetter
    self.setPieceState = setPieceState
    self.update = update
    self.tearDown = tearDown
end
