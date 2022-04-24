-- Selection.lua
-- Small class to handle highlighting the actively selected piece.

import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/object"
import "support"

local gfx <const> = playdate.graphics

-- How much larger than the piece to draw the selection in px.
local extraRadius <const> = 2

-- The thickness of the surrounding line in px.
local lineWidth <const> = 3

class('Selection').extends()

function Selection:init(origin, squareSize, squareMargin)
    Selection.super.init(self)

    local sprite = gfx.sprite.new()
    local isHidden = false

    local function moveTo(self, row, position)
        isHidden = false

        local x = ((position - 1) * squareSize.width)
            + ((position - 1) * squareMargin)
            + origin.x
            - extraRadius

        local y = ((row - 1) * squareSize.height)
            + ((row - 1) * squareMargin)
            + origin.y
            - extraRadius

        sprite:setBounds(
            x,
            y,
            squareSize.width + (extraRadius * 2),
            squareSize.height + (extraRadius * 2)
        )

        sprite:markDirty()
    end

    -- When the player highlights the submit button, we don't want to be highlighting a piece too.
    local function hide(self)
        isHidden = true
        sprite:markDirty()
    end

    function sprite:draw(x, y, width, height)
        if isHidden then
            return
        end

        doInGraphicsContext(function ()
            gfx.setColor(gfx.kColorBlack)
            gfx.setLineWidth(lineWidth)
            gfx.drawRect(0, 0, self.width, self.height)
        end)
    end

    sprite:add()

    self.moveTo = moveTo
    self.hide = hide
end
