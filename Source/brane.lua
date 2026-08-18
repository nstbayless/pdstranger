import "constants"
import "entities"

State = {
    -- map tidx -> tile string
    tiles={},
    
    -- map tidx -> ent object
    ents={},
    
    frames_per_anim_tick = 7,
    
    -- ticks at FPS
    frame = 0,
    
    -- ticks at FPS / frames_per_anim_tick
    frame_animation = 0,
    
    -- increments once per player action
    round = 1,
}

function tick_frame()
    State.frame += 1
    State.frame_animation += 1.0/State.frames_per_anim_tick
end

function pcoord_of(x, y)
    if not y then
        x, y = tcoord_of(x)
    end
    return x*GW, y*GH
end

function tidx_of(x,y)
    return y*W + x + 1
end

function tcoord_of(tidx)
    tidx -= 1
    return tidx % W, math.floor(tidx / W)
end

function tile_at(x, y)
    local tidx
    if y == nil then
        tidx = x
    else
        tidx = tcoord_of(x, y)
    end
    
    return State.tiles[tidx]
end

function ent_at(x, y)
    local tidx
    if y == nil then
        tidx = x
    else
        tidx = tcoord_of(x, y)
    end
    
    return State.ents[tidx]
end

-- loads an object (entity or tile) at the given location,
-- returns the object type as "entity", "tile", or nil
function load_object(x, y, glyph)
    local tidx = tidx_of(x, y)
    local lookup = OBJLOOKUP_BY_GLYPH[glyph]
    local objkey = lookup.key
    local state = lookup.config
    if not objkey then
        assert(false, "no objkey found for '" .. glyph .. "'")
        return nil
    end
    local obj = OBJLOOKUP[objkey]
    if not obj then
        assert(false, "no object found for '" .. glyph .. "'")
        return nil
    end
    if obj.til then
        State.tiles[tidx] = objkey
    elseif obj.entity then
        local e = {
            base=obj,
            tidx=tidx,
            state=state
        }
        
        entity_init(e)
        
        State.ents[tidx] = e
    else
        assert(false, "unknown object type for '" .. glyph .. "'")
        return nil
    end
end