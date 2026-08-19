import "constants"
import "entities"

State = {
    -- map tidx -> tile string
    tiles={},
    
    -- map tidx -> tile state info
    tiles_state={},
    
    -- map tidx -> ent object
    ents={},
    
    -- set tidx
    explosions = {},
    
    -- map tidx -> list of entities intending to move there
    entity_moving_to={},
    
    frames_per_anim_tick = 13,
    
    -- ticks at FPS
    frame = 0,
    
    -- ticks at FPS / frames_per_anim_tick
    frame_animation = 0,
    
    -- standard actions per second
    action_speed = 5.3,
    
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
    return x*GW + XOFF, y*GH + YOFF
end

function tidx_of(x,y)
    if x < 0 or y < 0 or x >= W or y >= H then
        return nil
    end
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
        tidx = tidx_of(x, y)
    end
    
    if not tidx then
        return nil
    end
    
    return State.tiles[tidx], State.tiles_state[tidx]
end

function ent_at(x, y)
    local tidx
    if y == nil then
        tidx = x
    else
        tidx = tidx_of(x, y)
    end
    
    return State.ents[tidx]
end

-- loads an object (entity or tile) at the given location,
-- returns the object type as "entity", "tile", or nil
-- second return value is object key string
function load_object(x, y, glyph)
    local tidx = tidx_of(x, y)
    local lookup = OBJLOOKUP_BY_GLYPH[glyph]
    if not lookup then
        return nil, nil
    end
    local objkey = lookup.key
    local state = lookup.config
    if not objkey then
        assert(false, "no objkey found for '" .. glyph .. "'")
        return nil, nil
    end
    local obj = OBJLOOKUP[objkey]
    if not obj then
        assert(false, "no object found for '" .. glyph .. "'")
        return nil, nil
    end
    if obj.tile then
        State.tiles[tidx] = objkey
        State.tiles_state[tidx] = state
        return "tile", objkey
    elseif obj.entity then
        local e = {
            base=obj,
            basekey=objkey,
            tidx=tidx,
            state=state
        }
        
        assert(tidx, "null tidx")
        
        entity_init(e)
        
        State.ents[tidx] = e
        return "entity", objkey
    else
        assert(false, "unknown object type for '" .. glyph .. "'")
        return nil, nil
    end
end

function load_hud()
    for x=0,W-1 do
        tidx = tidx_of(x, H-1)
        State.tiles[tidx] = 'hud'
        State.tiles_state[tidx] = nil
    end
end