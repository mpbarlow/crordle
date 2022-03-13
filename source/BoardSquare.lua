import "CoreLibs/graphics"
import "CoreLibs/animator"

local gfx <const> = playdate.graphics

local letters <const> = {
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S",
    "T", "U", "V", "W", "X", "Y", "Z"
}

-- BoardSquare encapsulates a single letter selection.
-- Rendering is modelled as an endlessly scrolling, wrapping list. The previous, current, and next
-- letters are rendered size.height pixels apart, with the entire thing shifted by offset % height.
-- The current letter seamlessly becomes the last letter (and the next the current) as scrolling
-- occurs, by mapping the offset over the 26 letters.
class('BoardSquare', {
    -- Stores the scroll offset, from 0 to 26 * size.height.
    offset = 0,

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

    -- Use the current scroll offset to determine how far through the list of letters we are.
    currentIndex = function(self)
        return math.floor(self.offset / self.size.height) + 1
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

    -- Handle the player pressing up or down to cycle through letters instead of using the crank.
    handleInput = function(self, button)
        -- This looks a little weird, but the offset is 0-based while currentIndex is 1-based.
        -- (currentIndex - 1) * height gives us the center offset of the current letter, so we can
        -- then subtract or add one whole square size to get the center point of the prev/next.
        -- We don't want to use previousIndex because that will wrap, causing an animation from A
        -- backwards to Z to scroll through 26 letters forwards, instead of 1 backwards.
        if (button == playdate.kButtonUp) then
            self:createAnimatorTo(((self:currentIndex() - 1) * self.size.height) - self.size.height)
        elseif (button == playdate.kButtonDown) then
            self:createAnimatorTo(((self:currentIndex() - 1) * self.size.height) + self.size.height)
        end
    end,

    -- Create a new animator from the current offset to the given value.
    createAnimatorTo = function(self, to)
        self.animator = gfx.animator.new(250, self.offset, to)
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

        -- To keep the draw logic simple, we always draw the current, previous, and next letter,
        -- taking advantage of sprite clipping to only show what should be visible.
        local prevLetter = letters[boardSquare:previousIndex()]
        local currentLetter = letters[boardSquare:currentIndex()]
        local nextLetter = letters[boardSquare:nextIndex()]

        -- getTextSize reports back a height of 20px which doesn't seem to be right...
        local prevWidth = gfx.getTextSize("*" .. prevLetter .. "*")
        local currentWidth = gfx.getTextSize("*" .. currentLetter .. "*")
        local nextWidth = gfx.getTextSize("*" .. nextLetter .. "*")

        -- The relative scroll offset within the height of the square.
        local relativeOffset = boardSquare.offset % self.height

        gfx.drawText(
            "*" .. prevLetter .. "*",
            self.width / 2 - prevWidth / 2,
            7 - relativeOffset - self.height
        )

        gfx.drawText(
            "*" .. currentLetter .. "*",
            self.width / 2 - currentWidth / 2,
            7 - relativeOffset
        )

        gfx.drawText(
            "*" .. nextLetter .. "*",
            self.width / 2 - nextWidth / 2,
            7 - relativeOffset + self.height
        )
    end

    sprite:setBounds(origin.x, origin.y, size.width, size.height)
    sprite:add()

    self.sprite = sprite
end
