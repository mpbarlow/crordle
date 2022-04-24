-- SubmitButton.lua
-- A small class to handle drawing the button the player presses to submit their word.

import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/object"
import "support"

local gfx <const> = playdate.graphics
local bounds <const> = playdate.geometry.rect.new(215, 95, 150, 40)

class('SubmitButton').extends()

function SubmitButton:init()
    SubmitButton.super.init()

    local sprite <const> = gfx.sprite.new()
    local isHighlighted = false

    -- Configure how the submit button draws itself.
    function sprite:draw(x, y, width, height)
        doInGraphicsContext(function ()
            -- If highlighted, fill the button and draw white text.
            if isHighlighted then
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRoundRect(0, 2, self.width, self.height - 2, 15)

                gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

            -- Otherwise, draw black text on an outline button
            else
                -- 3D/shadow effect
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRoundRect(0, 2, self.width, self.height - 2, 15)

                -- Fill the background in
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRoundRect(0, 0, self.width, self.height - 2, 15)

                -- Draw outline
                gfx.setColor(gfx.kColorBlack)
                gfx.drawRoundRect(0, 0, self.width, self.height - 2, 15)

                gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
            end

            local font <const> = fonts.regular
            gfx.setFont(font)

            -- Just looks visually off without the + 1
            local textCenterY = ((self.height - font:getHeight()) / 2) + 1

            if isHighlighted then
                textCenterY += 2
            end

            gfx.drawTextAligned("Submit", self.width / 2, textCenterY, kTextAlignment.center)
        end)
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
