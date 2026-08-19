function TILES.stair.get_animkey()
    for i=1,TIDX_MAX do
        if tile_at(i) == "button" then
            return "off"
        end
    end
    
    return "on"
end

function TILES.wall.cliff(x, y, tstate)
    if string.sub(tstate, #tstate) == "2" then
        return false
    end
    return true
end

function draw_tile(x, y, tstring, tstate)
    local base = TILES[tstring]
    local px, py = pcoord_of(x, y)
    
    -- draw cliff
    if y < H - 1 then
        local cliff = base.cliff
        if type(cliff) == "function" then
            cliff = cliff(x, y, tstate)
        end
        if cliff then
            local below = TILES[tile_at(x, y + 1)]
            if below and below.transparent then
                draw_gfx(px, py + GH, TILE_CLIFF)
            end
        end
    end
    
    -- draw tile
    local anim = base.anim
    if type(anim) == "number" then
        draw_gfx(px, py, anim)
    elseif type(anim) == "table" then
        if base.get_animkey then
            local key = base.get_animkey(x, y, tstate)
            draw_gfx(px, py, anim[key])
        elseif anim[tstate] then
            draw_gfx(px, py, anim[tstate])
        end
    end
end

-- TODO: optimize (cache until tile updated)
function draw_tiles()
    for y = 0,H-1 do
        for x = 0,W-1 do
            local t, state = tile_at(x, y)
            if t then
                draw_tile(x, y, t, state)
            end
        end
    end
end