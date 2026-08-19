import "constants"
import "brane"

function load_brane(path)
    local file = playdate.file.open(path, playdate.file.kFileRead)
    if not file then
        error("brane not found: " .. path)
    end
    
    -- clear relevant state
    State.tiles = {}
    State.ents = {}
    State.path = path

    local lines = {}
    while true do
        local l = file:readline()
        if not l then
            break
        end
        table.insert(lines, l)
    end

    for row, line in ipairs(lines) do
        if row >= H then
            break
        end
        local col = 0
        local i = 1
        while i <= #line and col < W do
            local tglyph = line:sub(i, i)
            local wtglyph = line:sub(i, i + 1)
            local ent_glyph = line:sub(i + 1, i + 1)

            if not load_object(col, row-1, wtglyph) then
                local t, objkey = load_object(col, row-1, tglyph)

                if ent_glyph ~= " " then
                    load_object(col, row-1, ent_glyph)
                end
            end

            i += 2
            col += 1
        end
        
        -- pad with void
        while col < W do
            load_object(col, row-1, ' ')
            col += 1
        end
    end
    
    for row = #lines,H-2 do
        col = 0
        while col < W do
            load_object(col, row-1, ' ')
            col += 1
        end
    end
    
    load_hud()
end
