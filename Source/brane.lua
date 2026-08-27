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
    
    -- list of {tile=, x=, y=, t=}
    particles = {},
    
    -- list of falling objects {anim=, tidx=, frame=}
    fallers = {},
    
    -- map tidx -> list of entities intending to move there
    entity_moving_to={},
    
    -- list of entities who will kill the player this round
    entity_killing_player={},
    
    -- list of entities who have just pushed something,
    -- or are in some other animation
    entity_animating={},
    
    -- set of tidx->true e.g. explo
    tiles_triggered={},
    
    -- set: tidx
    empty_chests={},
    
    -- ticks at FPS
    frame = 0,
    
    -- animate tiles that have entities on them.
    -- increases at 1.0/s
    -- occasionally reset to 0
    tile_visitor_heartbeat = VISITOR_HEARTBEAT_TIME*0.8,
    
    -- ticks with music
    -- each integer represents a beat
    frame_animation = 0,
    
    -- standard actions per second
    action_speed = DEFAULT_ACTION_SPEED,
    
    -- increments once at start of player action
    round = 0,
    
    memento = nil,
    
    eggmessage = {},
    props = {},
    brane_number = 1,
    memento = false,
    levzap = false,
    atone = false,
    voidcondition = nil,
    time_since_action = 1000,
    
    -- path to brane file
    path = nil,
}

CLEAN_STATE = table.deepcopy(State)

function tick_frame()
    State.frame += 1
    State.frame_animation = music_get_beat()
    State.tile_visitor_heartbeat += 1.0/FPS
    if State.tile_visitor_heartbeat >= VISITOR_HEARTBEAT_TIME then
        State.tile_visitor_heartbeat = 0
    end
    State.time_since_action += 1.0/FPS
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

function add_entity(e, tidx, init)
    assert(tidx, "null tidx")
    e.tidx = tidx
    State.entity_idx += 1
    e.entity_idx = State.entity_idx
    if init ~= false then
        entity_init(e)
    end
    State.ents[tidx] = e
    return e
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
        
        add_entity(e, tidx, false)
        
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
    if State.nextbrane then
        return State.nextbrane
    end
    if not State.brane_number then
        return WHITE_BRANE
    end
    return string.format("branes/b%03d", State.brane_number + 1)
end

function exit_by_stairs()
    local player = get_player()
    assert(player)
    local player_x, player_y = tcoord_of(player.tidx)
    player.fly = false
    
    if State.memento and State.memento.collected then
        -- permanent memento collect
        if collect_memento(true) then
            table.insert(State.particles, {tile=TILE_HUD_MEMENTO, x=player_x, y=player_y-0.6, invert=true, raise=true})
        end
    end
    
    local en = ent_at(player_x, player_y - 1)
    if en and en.base.cif then
        en.flashing = true
        en.visible_state_t = 0.5
        State.atone=true
        pushAction({type="atone", speed=1.0/6.0, t=0})
        enqueue_sfx("snd_activate")
    else
        -- exit animation
        player.frame_animation = 0
        player.frame_animation_speed = 7
        enqueue_sfx("snd_stairs")
        pushAction({type="fadeout", speed=1.0/1.2, t=0, iris={x=player_x+(player.offx or 0), y=player_y+(player.offy or 0)}, nextbrane=get_stairs_brane()})
    end
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
    "i1",
    "i2",
    "i3",
    
    "i4",
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
            tstate = "_brane"
        elseif type(itile) == "string" and string.sub(itile, 1, 1) == "i" then
            burden_idx = string_to_number(string.sub(itile, 2, 2))
            if burden_idx and GlobalState.burdens[burden_idx] then
                tstate = "_" .. itile
            else
                tstate = "_n" .. itile
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

function getLivesFromHUD()
    local tidx = find_tile("hud", "_locust")
    if not tidx and not tile_in_storage("hud", "_locust") then
        -- no normal HUD here, can gain specially.
        return GlobalState.lives
    else
        -- check HUD tile count
        local x,y = tcoord_of(tidx)
        local ntidx = tidx_of(x + 1, y)
        if ntidx then
            local nt, ntstate = tile_at(ntidx)
            if nt == "hud" then
                local nloc = string_to_number(ntstate)
                if nloc then
                    return nloc
                end
            end
        end
    end
    
    return 0
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
    if State.rod_storage and State.rod_storage.tstring == "button" then
        return true
    end
    
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

function collect_memento(permanent)
    if not State.memento then return end
    if permanent then
        State.memento.collected = true
        if not GlobalMementos[State.memento.tag] then
            GlobalMementos[State.memento.tag] = true
            enqueue_sfx("snd_token_collect")
            playdate.datastore.write(GlobalMementos, "memento", true)
            return true
        end
    else
        State.memento.collected = true
    end
    
    return false
end

-- returns -1 if not available
-- returns 0 if doesn't have it
-- returns 1 if has it temporarily
-- returns 2 if has it permanently
function has_memento()
    if GlobalState.void then return -1 end
    if not State.memento then return 0 end
    if not GlobalMementos then return 0 end
    if GlobalMementos[State.memento.tag] then
        return 2
    elseif State.memento.collected then
        return 1
    end
    return 0
end