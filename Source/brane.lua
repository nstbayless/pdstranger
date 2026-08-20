import "constants"
import "entities"

State = {
    -- map tidx -> tile string
    tiles={},
    
    -- map tidx -> tile state info
    tiles_state={},
    
    -- map tidx -> ent object
    ents={},
    
    rod_storage = nil,
    
    -- map tidx -> true or anim
    explosions = {},
    
    -- map tidx -> list of entities intending to move there
    entity_moving_to={},
    
    -- list of entities who will kill the player this round
    entity_killing_player={},
    
    -- list of entities who have just pushed something,
    -- or are in some other animation
    entity_animating={},
    
    frames_per_anim_tick = 13,
    
    -- ticks at FPS
    frame = 0,
    
    -- ticks at FPS / frames_per_anim_tick
    frame_animation = 0,
    
    -- standard actions per second
    action_speed = DEFAULT_ACTION_SPEED,
    
    -- increments once at start of player action
    round = 0,
    
    brane_number = 1,
    memento = false,
    
    -- path to brane file
    path = nil,
}

CLEAN_STATE = table.deepcopy(State)

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

function add_entity(e, tidx)
    assert(tidx, "null tidx")
    e.tidx = tidx
    entity_init(e)
    State.ents[tidx] = e
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
            basekey=objkey,
            state=state
        }
        
        assert(tidx, "null tidx")
        
        add_entity(e, tidx)
        
        return "entity", objkey
    else
        assert(false, "unknown object type for '" .. glyph .. "'")
        return nil, nil
    end
end

function reset_state()
    State = table.deepcopy(CLEAN_STATE)
end

function get_stairs_brane()
    return string.format("branes/b%03d", State.brane_number + 1)
end

local INTERFACE_TILES = {
    "memento",
    "HP0",
    "HP1",
    false,
    
    "LOC0",
    "LOC1",
    false,
    "rod",
    
    false,
    "i0",
    "i1",
    "i2",
    
    "i3",
    false,
    "b0",
    "b1",
}

function load_hud()
    for x=0,W-1 do
        local tidx = tidx_of(x, H-1)
        State.tiles[tidx] = 'hud'
        local tstate = nil
        local itile = INTERFACE_TILES[x+1]
        
        if itile == "memento" then
            tstate = "_memento"
        elseif itile == "HP0" then
            if GlobalState.void then
                tstate = "VO"
            else
                tstate = "HP"
            end
        elseif itile == "HP1" then
            if GlobalState.void then
                tstate = "ID"
            else
                tstate = string.format("%02d", math.min(GlobalState.hp, 99) % 100 % 100)
            end
        elseif itile == "LOC0" then
            tstate = "_locust"
        elseif itile == "LOC1" then
            tstate = string.format("%02d", math.min(GlobalState.lives, 99) % 100)
        elseif itile == "rod" then
            tstate = "_rod"
        elseif itile == "b0" then
            if State.brane_number then
                tstate = string.format("B%0d", math.floor(State.brane_number/100)%10)
            else
                tstate = "B?"
            end
        elseif itile == "b1" then
            if State.brane_number then
                tstate = string.format("%02d", State.brane_number%100)
            else
                tstate = "??"
            end
        end
        
        State.tiles_state[tidx] = tstate
    end
end

function find_hud_tidx(state)
    for i = 1,TIDX_MAX do
        
    end
end

function tile_in_storage(tstring, state)
    if State.rod_storage == nil then
        return false
    elseif State.rod_storage.tstring == tstring then
        if not state or State.rod_storage.state == state then
            return true
        end
    end
    return false
end

function find_tile(tstring, state)
    for i=1,TIDX_MAX do
        if State.tiles[i] == tstring then
            if State.tiles_state[i] == state or not state then
                return i
            end
        end
    end
    return nil
end

-- returns false, or distance
-- second/third RA are dx, dy (unless return false)
function has_line_of_sight(x0, y0, x1, y1)
    -- must be orthogonal
    if x0 ~= x1 and y0 ~= y1 then
        return false
    end
    
    dx = sign(x1 - x0)
    dy = sign(y1 - y0)
    local cx = x0 + dx
    local cy = y0 + dy
    local obstacle = false
    local i = 1
    while (cx ~= x1 or cy ~= y1) do
        local tile = tile_at(cx, cy)
        local e = ent_at(cx, cy)
        if not tile or TILES[tile].solid then
            return false
        end
        if e then
            return false
        end
        cx += dx
        cy += dy
        i += 1
    end
    
    return i, dx, dy
end

-- returns true if successful
function gainLife(n)
    n = n or 1
    
    local tidx = find_tile("hud", "_locust")
    
    if not tidx and not tile_in_storage("hud", "_locust") then
        -- no normal HUD here, can gain specially.
        GlobalState.lives += n
        return true
    else
        -- check HUD tile count
        local x,y = tcoord_of(tidx)
        local ntidx = tidx_of(x + 1, y)
        if ntidx then
            local nt, ntstate = tile_at(ntidx)
            if nt == "hud" then
                local nloc = string_to_number(ntstate)
                if nloc then
                    -- adjacent to HUD tile with locust count
                    GlobalState.lives = nloc + n
                    State.tiles_state[ntidx] = string.format("%02d", GlobalState.lives)
                    return true
                end
            end
        end
    end
end

function get_stairs_locked()
    for i=1,TIDX_MAX do
        if tile_at(i) == "button" then
            if not ent_at(i) then
                return true
            end
        end
    end
    
    return false
end

function check_player_reached_stairs()
    local player = get_player()
    if not player then return false end
    
    local tstring = tile_at(player.tidx)
    if not tstring then return false end
    
    if TILES[tstring].stair then
        if not get_stairs_locked() then
            return true
        end
    end
    
    return false
end