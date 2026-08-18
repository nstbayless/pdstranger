import "constants"

function ENTS.octahedron.init(e)
    e.state = "idle" or e.state
end

function entity_init(e)
    local base = e.base
    if e.base.init then
        e.base.init(e)
    end
end

function draw_entity(e)
    local base = e.base
    local px, py = pcoord_of(e.tidx)
    
    local anim = e.anim
    if type(anim) == "number" then
        draw_gfx(px, py, anim)
    elseif type(anim) == "table" then
        if anim[1] then
            draw_anim(px, py, anim)
        else
            anim = anim[e.state]
            if anim then
                draw_anim(px, py, anim)
            end
        end
    end
end

function draw_entities()
    for y = 0,H-1 do
        for x = 0,W-1 do
            local e = ent_at(x, y)
            if e then
                draw_entity(e)
            end
        end
    end
end