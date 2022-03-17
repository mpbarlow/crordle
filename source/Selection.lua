import "CoreLibs/object"

local gfx <const> = playdate.graphics

local extraRadius <const> = 2
local lineWidth <const> = 3

class('Selection').extends()

function Selection:init(origin, squareSize, squareMargin)
    Selection.super.init(self)

    local sprite = gfx.sprite.new()
    local hidden = false

    local function moveTo(self, row, position)
        hidden = false

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

    local function setHidden(self)
        hidden = true
        sprite:markDirty()
    end

    function sprite:draw(x, y, width, height)
        if hidden then
            return
        end

        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(lineWidth)
        gfx.drawRect(0, 0, self.width, self.height)
    end

    sprite:add()

    self.moveTo = moveTo
    self.setHidden = setHidden
end
