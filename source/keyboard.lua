import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

local layout <const> = {
    {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"},
    {"A", "S", "D", "F", "G", "H", "J", "K", "L"},
    {"Z", "X", "C", "V", "B", "N", "M"}
}

local font       = gfx.getSystemFont(gfx.font.kVariantBold)
local fontHeight = font:getHeight()

local origin <const> = {x = 200, y = 165}
local size <const>   = {width = 20, height = 25}

local keyboard = {}
local selected = {row = 1, position = 1}

function setupKeyboard()
    for rowIndex, row in ipairs(layout) do
        keyboard[rowIndex] = keyboard[rowIndex] or {}

        -- Set an offset for each row so each is centered
        local leftPadding = math.ceil(((10 - #row) * size.width) / 2)

        for position, letter in ipairs(row) do
            local sprite = gfx.sprite.new()

            sprite.char = letter

            -- We are highlighted if our position matches the selected position
            sprite.highlighted = function ()
                return rowIndex == selected.row and position == selected.position
            end

            sprite.draw = function (self, x, y, width, height)
                -- If we're highlighted, draw a black round-rect background and switch to white text
                if (self.highlighted()) then
                    gfx.setColor(gfx.kColorBlack)
                    gfx.fillRoundRect(0, 0, size.width, size.height, 3)

                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                end

                -- Draw the appropriate letter in the center of the sprite
                font:drawTextAligned(self.char,
                                     math.ceil(self.width / 2),
                                     math.ceil((self.height - fontHeight) / 2),
                                     kTextAlignment.center)

                -- Reset back to original drawing mode
                gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
            end

            -- Set the sprite bounds to the correct location and size on-screen
            sprite:setBounds(origin.x + leftPadding + ((position - 1) * size.width),
                             origin.y + ((rowIndex - 1) * size.height),
                             size.width,
                             size.height)

            sprite:add()

            keyboard[rowIndex][position] = sprite
        end
    end

    return keyboard
end

function handleInput(button)
    -- Mark the previously selected letter as needing a redraw
    keyboard[selected.row][selected.position]:markDirty()

    -- If we're pressing up or down, move between rows, making sure to limit the position selection
    -- to the last position in the new row
    if (button == playdate.kButtonUp) then
        if selected.row == 1 then
            selected.row = #keyboard
        else
            selected.row -= 1
        end

        selected.position = math.min(selected.position, #keyboard[selected.row])
    elseif (button == playdate.kButtonDown) then
        if selected.row == #keyboard then
            selected.row = 1
        else
            selected.row += 1
        end

        selected.position = math.min(selected.position, #keyboard[selected.row])
    -- If we're moving left or right, update the position
    elseif (button == playdate.kButtonLeft) then
        if selected.position == 1 then
            selected.position = #keyboard[selected.row]
        else
            selected.position -= 1
        end
    elseif (button == playdate.kButtonRight) then
        if selected.position == #keyboard[selected.row] then
            selected.position = 1
        else
            selected.position += 1
        end
    end

    -- Finally, mark the newly selected letter as needing a redraw
    keyboard[selected.row][selected.position]:markDirty()
end
