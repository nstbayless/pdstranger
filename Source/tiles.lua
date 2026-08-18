function draw_tile(tstring, x, y)
    local base = TILES[tstring]
    local px, py = pcoord_of(x, y)
    local anim = base.anim
    if type(anim) == "number" then
        draw_gfx(px, py, anim)
    elseif type(anim) == "table" then
        if base.get_animkey then
            local key = base.get_animkey(x, y)
            draw_gfx(px, py, anim[key])
        end
    end
end

-- TODO: optimize (cache until tile updated)
function draw_tiles()
    for y = 0,H-1 do
        for x = 0,W-1 do
            local t = tile_at(x, y)
            if t then
                draw_tile(t, x, y)
            end
        end
    end
end