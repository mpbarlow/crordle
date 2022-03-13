import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

local font       = gfx.getSystemFont(gfx.font.kVariantBold)
local fontHeight = font:getHeight()

-- Configures and returns a sprite to perform the actual key drawing based on highlighted state
--  key: the parent key instance, allowing the draw callback to check the highlight state
--  origin: {x, y} table storing the top-left point to draw the sprite
--  size: {width, height} table storing the size to draw the sprite
local function initSprite(key, origin, size)
    local sprite = gfx.sprite.new()

    function sprite:draw(x, y, width, height)
        -- If we're highlighted, draw a black round-rect background and switch to white text
        if (key.highlighted) then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRoundRect(0, 0, self.width, self.height, 3)

            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end

        -- Draw the appropriate letter in the center of the sprite
        font:drawTextAligned(
            key.letter,
            math.ceil(self.width / 2),
            math.ceil((self.height - fontHeight) / 2),
            kTextAlignment.center
        )

        -- Reset back to original drawing mode
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    end

    sprite:setBounds(origin.x, origin.y, size.width, size.height)
    sprite:add()

    return sprite
end

class('Key', {
    letter = "",
    highlighted = false,
    setHighlighted = function (self, highlighted)
        self.highlighted = highlighted
        self.sprite:markDirty()
    end
}).extends()

function Key:init(letter, origin, size)
    Key.super.init(self)

    self.letter = letter
    self.sprite = initSprite(self, origin, size)
end
