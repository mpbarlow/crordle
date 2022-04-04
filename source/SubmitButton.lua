import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/object"

local gfx <const> = playdate.graphics
local bounds <const> = playdate.geometry.rect.new(215, 100, 150, 40)

class('SubmitButton').extends()

function SubmitButton:init()
    SubmitButton.super.init()

    local sprite <const> = gfx.sprite.new()
    local isHighlighted = false

    -- Configure how the submit button draws itself.
    function sprite:draw(x, y, width, height)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(1)

        -- If highlighted, fill the button and draw white text.
        if isHighlighted then
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.fillRoundRect(0, 0, self.width, self.height, 15)

        -- Otherwise, draw black text on an outline button
        else
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

            -- Fill the background in
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(0, 0, self.width, self.height, 15)

            -- Draw outline
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRoundRect(0, 0, self.width, self.height, 15)
        end

        gfx.drawTextAligned(
            "*Submit*",
            self.width / 2,
            (self.height / 2) - 8,
            kTextAlignment.center
        )
    end

    sprite:setBounds(bounds)
    sprite:add()

    local function setHighlighted(self, highlighted)
        if highlighted == nil then
            highlighted = true
        end

        isHighlighted = highlighted
        sprite:markDirty()
    end

    self.setHighlighted = setHighlighted
end
