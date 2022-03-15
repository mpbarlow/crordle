import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/animator"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics

local letters <const> = {
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S",
    "T", "U", "V", "W", "X", "Y", "Z"
}

local rotationMultiplier <const> = 0.5
local animationDuration <const> = 250
local snapTimeout <const> = 1000

-- BoardSquare encapsulates a single letter selection.
-- Rendering is modelled as an endlessly scrolling, wrapping list. The previous, current, and next
-- letters are rendered size.height pixels apart, with the entire thing shifted by offset % height.
-- The current letter seamlessly becomes the last letter (and the next the current) as scrolling
-- occurs, by mapping the offset over the 26 letters.
class('BoardSquare', {
    -- Stores the scroll offset, from 0 to 26 * size.height.
    offset = 0,

    -- Squares that are not yet in play do not render a letter.
    inPlay = false,

    -- Move the offset by `change` to move the scroll window.
    moveOffset = function(self, change)
        self:setOffset(self.offset + change)
    end,

    -- Set the offset to an explicit value, wrapping at either end. The wrapping functionality
    -- allows us to not have to worry about whether any animators we use cross a wrap boundary
    -- (e.g. we can animate from 0 to -30 and this method will just handle it).
    setOffset = function(self, offset)
        local maxOffset = self.size.height * 26;

        if (offset < 0) then
            offset = offset + maxOffset
        elseif (offset >= maxOffset) then
            offset = offset - maxOffset
        end

        self.offset = offset
        self.sprite:markDirty()
    end,

    -- Return the letter index of a given scroll offset.
    indexOfOffset = function(self, offset)
        return math.floor(offset / self.size.height) + 1
    end,

    -- Use the current scroll offset to determine how far through the list of letters we are.
    currentIndex = function(self)
        return self:indexOfOffset(self.offset)
    end,

    -- Return the index of the previous letter, wrapping back round to the last if needed.
    previousIndex = function(self)
        local currentIndex = self:currentIndex()

        if (currentIndex - 1 <= 0) then
            return #letters
        end

        return currentIndex - 1
    end,

    -- Return the index of the next letter, wrapping back round to the first if needed.
    nextIndex = function(self)
        local currentIndex = self:currentIndex()

        if (currentIndex + 1 > #letters) then
            return 1
        end

        return currentIndex + 1
    end,

    -- Why this is a different value to currentIndex is not immediately obvious. currentIndex is
    -- whichever index/letter the top of the square is currently inside. However, having scrolled
    -- more than half a square in either direction, we're actually closer to the next/previous
    -- letter. As such, we want to snap to *that* letter, not back to whatever we were on before.
    closestIndex = function(self)
        return math.floor((self.offset / self.size.height) + 0.5) + 1
    end,

    -- Similarly to above, when the game asks us what letter we've selected, we want whatever
    -- letter we're going to snap to. This means speedy players won't be tripped up.
    closestLetter = function(self)
        return letters[self:closestIndex()]
    end,

    -- Animate to `moveBy` letters away
    moveLetter = function(self, moveBy)
        -- This looks a little weird, but the offset is 0-based while currentIndex is 1-based.
        -- (currentIndex - 1) * height gives us the top offset of the current letter, so we can
        -- then subtract or add n whole square sizes to get the top point of the prev/next.
        -- We don't want to use previousIndex because that will wrap, causing an animation from A
        -- backwards to Z to scroll through 26 letters forwards, instead of 1 backwards.
        self:animateTo(((self:currentIndex() - 1) * self.size.height) + (moveBy * self.size.height))
    end,

    -- Animate to the next letter.
    moveToNextLetter = function(self)
        self:moveLetter(1)
    end,

    -- Animate to the previous letter.
    moveToPreviousLetter = function(self)
        self:moveLetter(-1)
    end,

    -- Handle `change` degrees of crank rotation.
    handleCranking = function(self, change)
        -- If we're currently animating to a new selection from a button press, cancel it so the
        -- crank takes priority.
        self.animator = nil

        if (self.snapTimer == nil) then
            -- This timer will track how long it's been since cranking stopped, so after a brief
            -- pause we can snap the letter into place.
            self.snapTimer = playdate.timer.new(snapTimeout)
        end

        -- Reset the timer each time the crank moves so we don't time out while still moving.
        self.snapTimer:reset()

        self:moveOffset(change * rotationMultiplier)
    end,

    -- Create a new animator from the current offset to the given value.
    animateTo = function(self, to)
        self.animator = gfx.animator.new(animationDuration, self.offset, to)
    end,

    -- Do anything that needs to run on every frame.
    update = function(self)
        -- If we've configured an animator, get the next value and update our current offset to it.
        if (self.animator ~= nil) then
            -- If we're already animating something, that means that either a button was pressed,
            -- or our snap timer expired and we're animating it into place. In either case, we no
            -- longer want the timer to be running.
            if (self.snapTimer ~= nil) then
                self.snapTimer:remove()
                self.snapTimer = nil
            end

            self:setOffset(self.animator:currentValue())

            if (self.animator:ended()) then
                self.animator = nil
            end
        -- If we have a complete snapTimer, snap the letter into place.
        elseif (self.snapTimer ~= nil and self.snapTimer.timeLeft == 0) then
            -- Kill the timer to stop us getting into an infinite loop.
            self.snapTimer:remove()
            self.snapTimer = nil

            -- self.offset starts at the top of the square, so the logical snapping point from a
            -- visual perspective should act as if we were scrolled half a square further than we
            -- actually are, so line up with the center line.
            self:animateTo((self:closestIndex() - 1) * self.size.height)
        end
    end
}).extends()

function BoardSquare:init(origin, size)
    BoardSquare.super.init(self)

    self.size = size

    local boardSquare = self
    local sprite = gfx.sprite.new()

    function sprite:draw(x, y, width, height)
        -- Draw the border
        gfx.drawRect(0, 0, self.width, self.height)

        -- If the square is not in play it should not render a letter.
        if (not boardSquare.inPlay) then
            return
        end

        -- To keep the draw logic simple, we always draw the current, previous, and next letter,
        -- taking advantage of sprite clipping to only show what should be visible.
        local prevLetter = "*" .. letters[boardSquare:previousIndex()] .. "*"
        local currentLetter = "*" .. letters[boardSquare:currentIndex()] .. "*"
        local nextLetter = "*" .. letters[boardSquare:nextIndex()] .. "*"

        local prevWidth = gfx.getTextSize(prevLetter)
        local currentWidth = gfx.getTextSize(currentLetter)
        local nextWidth = gfx.getTextSize(nextLetter)

        -- getTextSize reports back a height of 20px which doesn't seem to be right...
        local letterHeight = 16

        -- The relative scroll offset within the height of the square.
        local relativeOffset = boardSquare.offset % self.height

        -- Draw the previous, current, and next letters one square height apart.
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

    self.sprite = sprite
end
