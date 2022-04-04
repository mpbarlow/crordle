import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/object"

local gfx <const> = playdate.graphics
local bounds <const> = playdate.geometry.rect.new(50, 70, 300, 100)

class("Modal").extends()

function Modal:init()
    Modal.super.init(self)

    local sprite <const> = gfx.sprite.new()

    -- Message to display in the modal. If this is nil, the modal does not draw.
    local modalMessage = nil

    local function isDisplaying(self)
        return modalMessage ~= nil
    end

    local function displayMessageForDuration(self, message, durationMs)
        if isDisplaying(self) then
            return
        end

        modalMessage = message
        sprite:markDirty()

        playdate.timer.performAfterDelay(durationMs, function ()
            modalMessage = nil
            sprite:markDirty()
        end)
    end

    -- Configure the modal sprite
    function sprite:draw(x, y, width, height)
        -- Don't draw anything if we have no modal to show
        if not isDisplaying(self) then
            return
        end

        -- Draw a filled white roundrect with a black border, with an offset dither pattern to work
        -- as a shadow.
        -- Shadow
        gfx.setDitherPattern(0.5)
        gfx.fillRoundRect(4, 4, self.width - 4, self.height - 4, 10)

        -- Filled background
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(2, 2, self.width - 4, self.height - 4, 10)

        -- Border
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRoundRect(2, 2, self.width - 4, self.height - 4, 10)

        -- Draw the message in the center of the roundrect.
        gfx.drawTextAligned(
            modalMessage,
            self.width / 2, (self.height / 2) - 8,
            kTextAlignment.center
        )
    end

    sprite:setBounds(bounds)
    sprite:setZIndex(10)
    sprite:add()

    self.isDisplaying = isDisplaying
    self.displayMessageForDuration = displayMessageForDuration
end

