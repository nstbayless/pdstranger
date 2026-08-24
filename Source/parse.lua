import "constants"
import "brane"

local function parse_command(argv)
    if #argv == 0 then return end
    if argv[1] == "nextbrane" then
        State.nextbrane = argv[2]
    elseif argv[1] == "voidcondition" then
        State.voidcondition = argv[2]
    elseif argv[1] == "egg" then    
        table.insert(State.eggmessage, argv[2])
    elseif argv[1] == "mus" then
        State.music = argv[2]
    elseif argv[1] == "ent" then
        local e = {}
        -- flags
        
        for i=#argv,1,-1 do
            local arg = argv[i]
            local pos = string.find(arg, "=")
            if pos then
                local key = string.sub(arg, 1, pos-1)
                local value = string.sub(arg, pos+1)
                e[key] = value
                table.remove(argv, i)
            end
        end
        
        e.basekey = argv[2]
        local x = string_to_number(argv[3] or "0")
        local y = string_to_number(argv[4] or "0")
        e.state = argv[5] or nil
        
        if not e.basekey then return end
        add_entity(e, tidx_of(x, y))
    end
end

function load_brane(path, retry)
    local file = playdate.file.open(path, playdate.file.kFileRead)
    if not file then
        return false
    end
    
    -- clear relevant state
    State.tiles = {}
    State.ents = {}
    State.path = path
    State.music = {}
    State.brane_number = nil
    
    if not retry then
        State.empty_chests = {}
    end
    
    for i=0,255 do
        if path == string.format("branes/b%03d", i) then
            State.brane_number = i
            break
        end
    end

    local lines = {}
    while true do
        local l = file:readline()
        if not l then
            break
        end
        table.insert(lines, l)
    end

    local maxrow = #lines
    for row, line in ipairs(lines) do
        if row >= H then
            break
        end
        if string.startswith(line, "%%") then
            maxrow = row-1
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
    
    for row = maxrow,H-2 do
        col = 0
        while col < W do
            load_object(col, row-1, ' ')
            col += 1
        end
    end
    
    -- additional info
    for _, line in ipairs(lines) do
        if string.startswith(line, "%%") then
            parse_command(string.split_respect_quotes(string.sub(line, 3)))
        end
    end
    
    load_hud()
    music_play(State.music)
    return true
end
