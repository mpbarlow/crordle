import "CoreLibs/object"

local gfx <const> = playdate.graphics

local extraRadius <const> = 2

class('ActiveRing', {
    moveTo = function(self, row, square)
        local x = ((square - 1) * self.squareSize.width)
            + ((square - 1) * self.squareMargin)
            + self.origin.x
            - extraRadius

        local y = ((row - 1) * self.squareSize.height)
            + ((row - 1) * self.squareMargin)
            + self.origin.y
            - extraRadius

        self.sprite:setBounds(
            x,
            y,
            self.squareSize.width + (extraRadius * 2),
            self.squareSize.height + (extraRadius * 2)
        )
    end
}).extends()

function ActiveRing:init(origin, squareSize, squareMargin)
    ActiveRing.super.init(self)

    self.origin = origin
    self.squareSize = squareSize
    self.squareMargin = squareMargin

    local sprite = gfx.sprite.new()

    function sprite:draw(x, y, width, height)
        gfx.setLineWidth(3)
        gfx.drawRect(0, 0, self.width, self.height)
        gfx.setLineWidth(1)
    end

    sprite:add()

    self.sprite = sprite
    self:moveTo(1, 1)
end
