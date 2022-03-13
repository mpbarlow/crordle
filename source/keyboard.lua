import "classes/Key"

local layout <const> = {
    {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"},
    {"A", "S", "D", "F", "G", "H", "J", "K", "L"},
    {"Z", "X", "C", "V", "B", "N", "M"}
}

local origin <const> = {x = 200, y = 165}
local size <const>   = {width = 20, height = 25}

local keyboard = {}
local selected = {row = 1, position = 1}

-- Iterate through the keyboard layout and instantiate a Key object for each. The Key object will
-- then handle configuring its own sprite.
function setupKeyboard()
    for rowIndex, row in ipairs(layout) do
        keyboard[rowIndex] = keyboard[rowIndex] or {}

        -- Set an offset for each row so each is centered
        local leftPadding = math.ceil(((10 - #row) * size.width) / 2)

        for position, letter in ipairs(row) do
            -- Offset the origin based on where in the keyboard we are
            keyboard[rowIndex][position] = Key(
                letter,
                {
                    x = origin.x + leftPadding + ((position - 1) * size.width),
                    y = origin.y + ((rowIndex - 1) * size.height)
                },
                size
            )
        end
    end

    keyboard[selected.row][selected.position]:setHighlighted(true)
end

function handleInput(button)
    -- Unhighlight the previously selected letter
    keyboard[selected.row][selected.position]:setHighlighted(false)

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

    -- Finally, highlight the newly selected letter
    keyboard[selected.row][selected.position]:setHighlighted(true)
end
