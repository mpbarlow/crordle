import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/animator"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics
local pieceStates <const> = constants.pieceStates

local letters <const> = {
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S",
    "T", "U", "V", "W", "X", "Y", "Z"
}

local lettersPerCrank <const> = 3
local animationDuration <const> = 250
local snapTimeout <const> = 1000

-- Piece encapsulates a single letter selection.
-- Rendering is modelled as an endlessly scrolling, wrapping list. The previous, current, and next
-- letters are rendered size.height pixels apart, with the entire thing shifted by offset % height.
-- The current letter seamlessly becomes the last letter (and the next the current) as scrolling
-- occurs, by mapping the offset over the 26 letters.
class('Piece', {
    -- Squares that are not yet in play do not render a letter.
    inPlay = false,

    -- Track the current play state of our piece. Each piece starts unchecked.
    pieceState = pieceStates.kSquareUnchecked
}).extends()

function Piece:init(origin, size)
    Piece.super.init(self)

    -- Alias self to allow the sprite draw callback to read data from this.
    local piece = self

    -- Store the letter index. This is the source of truth for what letter is actually selected in
    -- the piece.
    local index = 1
    local maxIndex <const> = #letters

    -- Stores the scroll offset, from 0 to 26 * size.height. Offset is used for drawing, not the
    -- selection of letters, however during cranking the offset does update the index based on the
    -- closest letter.
    local offset = 0
    local maxOffset <const> = size.height * #letters;

    local sprite = gfx.sprite.new()

    -- Handles animating to a new position when using the buttons.
    local animator = nil

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

        if (to > offset) then
            oppositeEquivalent = to - maxOffset
        else
            oppositeEquivalent = maxOffset + to
        end

        if (math.abs(oppositeEquivalent - offset) < math.abs(to - offset)) then
            to = oppositeEquivalent
        end

        animator = gfx.animator.new(animationDuration, offset, to)
    end

    -- Set the offset to an explicit value, wrapping at either end. The wrapping functionality
    -- allows us to not have to worry about whether any animators we use cross a wrap boundary
    -- (e.g. we can animate from 0 to -30 and this function will handle wrapping it for us).
    -- Because offset determines where the letter is drawn, we also mark the sprite as dirty.
    local function setOffset(newOffset)
        if (newOffset < 0) then
            newOffset += maxOffset
        elseif (newOffset >= maxOffset) then
            newOffset -= maxOffset
        end

        offset = newOffset
        sprite:markDirty()
    end

    -- Similar to setOffset, but allow us to set the current letter index instead.
    local function setIndex(newIndex)
        if (newIndex < 1) then
            newIndex += maxIndex
        elseif (newIndex > maxIndex) then
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

        if (currentIndex - 1 <= 0) then
            return #letters
        end

        return currentIndex - 1
    end

    -- Return the index of the next letter, wrapping back round to the first if needed.
    local function nextRenderIndex()
        local currentIndex = currentRenderIndex()

        if (currentIndex + 1 > maxIndex) then
            return 1
        end

        return currentIndex + 1
    end

    -- Handle `change` degrees of crank rotation.
    local function handleCranking(self, change)
        -- If we're currently animating to a new selection from a button press, cancel it so the
        -- crank takes priority.
        animator = nil

        if (snapTimer == nil) then
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

    local function getLetter(self)
        if (not self.inPlay) then
            return ""
        end

        return letters[index]
    end

    -- Do anything that needs to run on every frame.
    local function update(self)
        -- If we've configured an animator, get the next value and update our current offset to it.
        if (animator ~= nil) then
            -- If we're already animating something, that means that either a button was pressed,
            -- or our snap timer expired and we're animating it into place. In either case, we no
            -- longer want the timer to be running.
            if (snapTimer ~= nil) then
                snapTimer:remove()
                snapTimer = nil
            end

            setOffset(animator:currentValue())

            if (animator:ended()) then
                animator = nil
            end
        -- If we have a complete snapTimer, snap the letter into place.
        elseif (snapTimer ~= nil and snapTimer.timeLeft == 0) then
            -- Kill the timer to stop us getting into an infinite loop.
            snapTimer:remove()
            snapTimer = nil

            animateOffsetTo((closestIndexToOffset() - 1) * size.height)
        end
    end

    -- Drawing callback.
    function sprite:draw(x, y, width, height)
        -- Reset color and drawing modes.
        gfx.setColor(gfx.kColorBlack)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.setLineWidth(1)

        -- Draw the border.
        gfx.drawRect(0, 0, self.width, self.height)

        -- If the piece is not in play it should not render a letter.
        if (not piece.inPlay) then
            gfx.setDitherPattern(0.5)
            gfx.fillRect(1, 1, self.width - 2, self.height - 2)

            return
        end

        -- If our piece is totally wrong...
        if (piece.pieceState == pieceStates.kSquareIncorrect) then
            -- ...fill the piece black...
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(1, 1, self.width - 2, self.height - 2)

            -- ...and draw white text.
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end

        -- To keep the draw logic simple, we always draw the current, previous, and next letter,
        -- taking advantage of sprite clipping to only show what should be visible.
        local prevLetter = "*" .. letters[previousRenderIndex()] .. "*"
        local currentLetter = "*" .. letters[currentRenderIndex()] .. "*"
        local nextLetter = "*" .. letters[nextRenderIndex()] .. "*"

        local prevWidth = gfx.getTextSize(prevLetter)
        local currentWidth = gfx.getTextSize(currentLetter)
        local nextWidth = gfx.getTextSize(nextLetter)

        -- getTextSize reports back a height of 20px which doesn't seem to be right...
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
    end

    sprite:setBounds(origin.x, origin.y, size.width, size.height)
    sprite:add()

    -- Bind public methods
    self.moveLetter = moveLetter
    self.handleCranking = handleCranking
    self.getLetter = getLetter
    self.update = update
end
