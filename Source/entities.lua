import "constants"
import "pathfind"

function ENTS.octahedron.init(e)
    e.state = e.state or "idle"
    e.bias = "nswe"
end

function ENTS.beaver.init(e)
    e.state = e.state or "idle"
end

function ENTS.player.init(e)
    e.state = e.state or "s"
end

function ENTS.steus.onpit(e)
    State.explosions[e.tidx] = true
    State.tiles[e.tidx] = "floor"
    entity_die(e)
    return true
end

function ENTS.stgor.init(e)
    e.state = e.state or "off"
end

function ENTS.stgor.onpush(e)
    e.state = "on"
    e.flashing = true
    e.visible_state_t = SECONDARY_ANIMATIONS_TIME
end

function ENTS.stmon.update(e)
    local player = get_player()
    if not player then return end
    local player_x, player_y = tcoord_of(player.tidx)
    local x, y = tcoord_of(e.tidx)
    local los, dx, dy = has_line_of_sight(x, y, player_x, player_y)
    if los then
        e.flashing = true
        e.visible_state_t = 0.8
        player.flashing = true
        
        while los > 1 do
            x += dx
            y += dy
            local eidx = tidx_of(x, y)
            if eidx then
                State.explosions[eidx] = ANIM_ZAP[dir_to_cardinal(dx, dy)]
            end
            los -= 1
        end
        
        table.insert(State.entity_killing_player, e)
    end
end

function ENTS.stgor.solid(e)
    return e.state == "on"
end

function ENTS.sttan.update(e)
    -- check if any enemies (or NPCs) alive
    for tidx,e in pairs(State.ents) do
        if e.base.enemy then
            return
        end
    end
    
    e.flashing = true
    e.animation_time = 0.7
    table.insert(State.entity_animating, e)
end

function ENTS.sttan.on_animation_complete(e)
    State.explosions[e.tidx] = true
    entity_die(e)
end

function ENTS.stlev.init(e)
    e.state = e.state or "off"
end

function ENTS.mim.init(e)
    e.state = "s"
    if e.base.axis.y then
        e.state = "n"
    end
end
ENTS.mimx.init = ENTS.mim.init
ENTS.mimy.init = ENTS.mim.init
ENTS.mimxy.init = ENTS.mim.init

function ENTS.mim.update(e, dx, dy)
    if e.base.axis.x then dx *= -1 end
    if e.base.axis.y then dy *= -1 end
    
    e.state = dir_to_cardinal(dx, dy)
    entity_prepare_move(e, dx, dy)
end
ENTS.mimx.update = ENTS.mim.update
ENTS.mimy.update = ENTS.mim.update
ENTS.mimxy.update = ENTS.mim.update

-- tidx of cell entity is facing
function entity_facing_tidx(e)
    local x, y = tcoord_of(e.tidx)
    local dx, dy = cardinal_to_dir(e.state)
    return tidx_of(x + dx, y + dy)
end

function shades_pending()
    for _, e in pairs(State.ents) do
        if e.next_facing then
            return true
        end
    end
    return false
end

function shade_faces_tidx(tidx)
    for _, e in pairs(State.ents) do
        if e.base.shade and entity_facing_tidx(e) == tidx then
            return true
        end
    end
    return false
end

function ENTS.shade.update(e)
    local facing = e.next_facing
    if not facing then
        return
    end
    
    -- shade in front (blocking)
    local tidx = entity_facing_tidx(e)
    if tidx then
        local e2 = State.ents[tidx]
        if e2 ~= nil and e2.base.shade == true then
            return
        end
    end

    State.shades_advanced = true
    e.next_facing = nil

    local dx, dy = cardinal_to_dir(e.state)
    entity_prepare_move(e, dx, dy, MOVE_FLAG_IGNORE_SHADES | MOVE_FLAG_IGNORE_PLAYER)
    e.state = dir_to_cardinal(facing.dx, facing.dy)
end

function ENTS.player.draw(e)
    local px, py = pcoord_of(e.tidx)
    
    if e.rod_animation_timer then
        
        e.rod_animation_timer -= 1.0/FPS
        if e.rod_animation_timer <= 0 then
            e.rod_animation_timer = nil
        end
        
        local anim_ur = e.base.anim["ur" .. e.state]
        local anim_rod = e.base.anim["rod" .. e.state]
        local dx, dy = cardinal_to_dir(e.state)
        draw_anim(px, py, anim_ur, e.frame_animation)
        draw_anim(px + dx * GW, py + dy * GH, anim_rod, e.frame_animation)
        
        return true
    end
    
    return false
end

function ENTS.octahedron.update(e, dx, dy)
    local x,y = tcoord_of(e.tidx)
    local player = get_player()
    local path = nil
    if player then
        local dst_x, dst_y = tcoord_of(player.tidx)
        path = pathfind(x, y, dst_x, dst_y, e.bias)
        
        if not path then
            -- pathfind to player's previous location
            path = pathfind(x, y, dst_x - dx, dst_y - dy)
        end
    end
    
    if path and path[1] then
        local dstidx = path[1]
        local dstx, dsty = tcoord_of(dstidx)
        local dx = dstx - x
        local dy = dsty - y
        assert(math.abs(dx) + math.abs(dy) == 1, "first chain in path invalid")
        entity_prepare_move(e, dx, dy)
        e.state = "active"
    else
        e.state = "idle"
    end
end

function ENTS.leech.update(e)
    local dx, dy = cardinal_to_dir(e.state)
    local x, y = tcoord_of(e.tidx)
    dstidx = tidx_of(x + dx, y + dy)
    
    local blocker = get_entity_move_blocker(
        e, dx, dy,
        MOVE_FLAG_NO_PITS | MOVE_FLAG_NO_PUSH
    )
    if blocker == "pdie" then
        add_entity_killing_player(e)
    elseif blocker ~= nil then
        -- turn around
        e.state = dir_to_cardinal(-dx, -dy)
    else
        entity_prepare_move(e, dx, dy)
    end
end

ENTS.maggot.update = ENTS.leech.update

function ENTS.smiler.update(e)
    local player = get_player()
    if not player then
        return
    end
    
    local x, y = tcoord_of(e.tidx)
    
    local player_x, player_y = tcoord_of(player.tidx)
    
    local dx = 0
    local dy = 0
    
    if player_y == y and player_x < x then
        dx = -1
    elseif player_y == y and player_x > x then
        dx = 1
    elseif player_x == x and player_y < y then
        dy = -1
    elseif player_x == x and player_y > y then
        dy = 1
    end
    
    if dx ~= 0 or dy ~= 0 then
        local blocker = get_entity_move_blocker(
            e, dx, dy,
            MOVE_FLAG_NO_PUSH
        )
        if blocker == "pdie" then
            add_entity_killing_player(e)
            if dx < 0 then
                e.state = "w"
            elseif dx > 0 then
                e.state = "e"
            end
        elseif blocker == nil then
            if dx < 0 then
                e.state = "w"
            elseif dx > 0 then
                e.state = "e"
            end
            entity_prepare_move(e, dx, dy)
        end
    end
end

function ENTS.beaver.update(e)
    if e.state == "idle" then
        local player = get_player()
        if not player then
            return
        end
        
        local x, y = tcoord_of(e.tidx)
        
        local player_x, player_y = tcoord_of(player.tidx)
        
        local dx = 0
        local dy = 0
        
        if player_y == y and player_x < x then
            dx = -1
        elseif player_y == y and player_x > x then
            dx = 1
        elseif player_x == x and player_y < y then
            dy = -1
        elseif player_x == x and player_y > y then
            dy = 1
        end
        
        if dx ~= 0 or dy ~= 0 then
            if has_line_of_sight(x, y, player_x, player_y) then
                local blocker = get_entity_move_blocker(
                    e, dx, dy,
                    MOVE_FLAG_NO_PUSH | MOVE_FLAG_NO_PITS | MOVE_FLAG_IGNORE_PLAYER
                )
                if blocker == nil then
                    e.state = dir_to_cardinal(dx, dy)
                end
            end
        end
    end
    
    if e.state ~= "idle" then
        local dx, dy = cardinal_to_dir(e.state)
        
        local blocker = get_entity_move_blocker(
            e, dx, dy,
            MOVE_FLAG_NO_PUSH | MOVE_FLAG_NO_PITS
        )
        if blocker == "pdie" then
            add_entity_killing_player(e)
        elseif blocker then
            e.state = "idle"
        else
            entity_prepare_move(e, dx, dy)
        end
    end
end

function ENTS.chest.interact(e, ei, dx, dy)
    if dy == -1 then
        if e.state == "on" then
            e.state = "off"
            local nloc = e.count or 1
            
            if nloc <= 0 then
                push_dialogue("Empty.")
            elseif nloc == 1 then
                success = gainLife()
                if not success then
                    push_dialogue("Huh!? Where did it go..?")
                else
                    if not GlobalState.hasGottenLocust then
                        GlobalState.hasGottenLocust = true
                        if GlobalState.void then
                            push_dialogue("You found a locust idol!\nIt looks kind of tasty...")
                        else
                            push_dialogue("You found a locust idol!")
                            push_dialogue("Perhaps it will come in handy in the long run?")
                        end
                    end
                end
            else
                success = gainLife(nloc)
                if not success then
                    push_dialogue("Huh!? Where did they go..?")
                else
                    if not GlobalState.hasGottenLocustLucky then
                        GlobalState.hasGottenLocustLucky = true
                        push_dialogue(string.format("L U C K Y ! !"))
                    end
                end
            end
        else
            return false
        end
        
        ei.visible_state_t = 1.0
        ei.visible_state = "item"
        ei.state = "s"
        return 1
    end
end

function add_entity_killing_player(e)
    if not table.ihas(State.entity_killing_player, e) then
        table.insert(State.entity_killing_player, e)
    end
end

function entity_init(e)
    e.base = ENTS[e.basekey]
    if e.base.init then
        e.base.init(e)
    end
end

function draw_entity(e)
    local base = e.base
    local px, py = pcoord_of(e.tidx)
    
    px += (e.offx or 0) * GW
    py += (e.offy or 0) * GH
    
    if e.base.draw and e.base.draw(e) then
        return
    end
    
    local invert = false
    if e.flashing then
        if State.frame % 2 >= 1 then
            playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeInverted)
        end
    end
    
    local anim = base.anim
    if type(anim) == "number" then
        draw_gfx(px, py, anim)
    elseif type(anim) == "table" then
        if anim[1] then
            draw_anim(px, py, anim, e.frame_animation)
        else
            local state = e.visible_state or e.state
            anim = anim[state]
            if anim then
                draw_anim(px, py, anim, e.frame_animation)
            end
        end
    end
    
    if e.visible_state_t and e.visible_state_t > 0 then
        e.visible_state_t -= 1.0/FPS
        if e.visible_state_t <= 0 then
            e.visible_state = nil
            e.flashing = false
            e.frame_animation_speed = nil
            e.frame_animation = nil
        end
    end
    
    playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
end

function entity_visible(e)
    if State.levzap then
        return e.base.lev or e.base.player
    else
        return true
    end
end

function draw_entities()
    for y = 0,H-1 do
        for x = 0,W-1 do
            local e = ent_at(x, y)
            if e and entity_visible(e) then
                draw_entity(e)
                
                if e.frame_animation then
                    if e.frame_animation_speed then
                        e.frame_animation += e.frame_animation_speed / FPS
                    else 
                        e.frame += 1.0/state.frames_per_anim_tick
                    end
                end
            end
        end
    end
end

function can_push(e, dx, dy)
    -- a pushed entity crushes whatever it lands on, so entities don't block it
    local result = get_entity_move_blocker(
        e, dx, dy,
        MOVE_FLAG_NO_PUSH | MOVE_FLAG_NO_PUSHBLOCKER
    )
    return result == nil
end

function get_entity_solid(e)
    if type(e.base.solid) == "function" then
        return e.base.solid(e)
    else
        return e.base.solid
    end
end

-- returns nil if can move;
-- returns string if something blocks
-- second arg may indicate blocking entity
function get_entity_move_blocker(e, dx, dy, flags)
    flags = flags or 0
    local x, y = tcoord_of(e.tidx)
    local dstx, dsty = x + dx, y + dy
    
    local tile = TILES[tile_at(dstx, dsty) or "wall"]
    
    if tile.solid then
        return "stopped"
    elseif tile.pit and (flags & MOVE_FLAG_NO_PITS) ~= 0 then
        return "stopped"
    else
        local e2 = ent_at(dstx, dsty)
        if not e2 then
            return nil
        else
            local b, b2 = e.base, e2.base
            if get_entity_solid(e2) then
                return "stopped"
            elseif b2.shade and (flags & MOVE_FLAG_IGNORE_SHADES) ~= 0 then
                return nil
            elseif b2.pushblocker and (flags & MOVE_FLAG_NO_PUSHBLOCKER) ~= 0 then
                return "stopped"
            elseif b2.push then
                if (flags & MOVE_FLAG_NO_PUSH) ~= 0 then
                    return "stopped"
                end
                if can_push(e2, dx, dy) then
                    return "push", e2
                else
                    return "stopped"
                end
            elseif b2.enemy and b.enemy then
                return "stopped"
            elseif b2.enemy and (b.player or b.shade) then
                return "pdie", e2
            elseif b2.player and b.enemy and (flags & MOVE_FLAG_IGNORE_PLAYER) == 0 then
                return "pdie"
            else
                return nil
            end
        end
    end
end

function entity_clear_movephase()
    for i=1,TIDX_MAX do
        local e = ent_at(i)
        if e then
            e.queued_move = nil
        end
    end
    
    State.entity_moving_to = {}
end

function add_entity_moving_to(dstx, dsty, e)
    local tidx = tidx_of(dstx, dsty)
    local movers = State.entity_moving_to[tidx]
    if not movers then
        movers = {}
        State.entity_moving_to[tidx] = movers
    end
    if not table.ihas(movers, e) then
        table.insert(movers, e)
    end
end

-- return false if no interaction available
-- returns 1 if successful interaction
-- returns 2 if successful interaction that counts as a turn
function entity_interact(e, ei, dx, dy)
    if e.base.interact then
        return e.base.interact(e, ei, dx, dy)
    end
    return false
end

function entity_prepare_move(e, dx, dy, flags)
    local result, result_e = get_entity_move_blocker(e, dx, dy, flags)
    local x, y = tcoord_of(e.tidx)
    local dstx, dsty = x + dx, y + dy
    if result == nil then
        e.queued_move = {move=true, dx=dx, dy=dy}
        add_entity_moving_to(dstx, dsty, e)
    else
        e.queued_move = {blocked=result, e=result_e, dx=dx, dy=dy}
    end
end

function get_player()
    return get_entity_by_basekey("player")
end

function entity_count(basekey)
    local n = 0
    for key, e in pairs(State.ents) do
        if e.basekey == basekey then
            n += 1
        end
    end
    return n
end

function get_entity_by_basekey(basekey)
    for tidx, e in pairs(State.ents) do
        if e.basekey == basekey then
            return e
        end
    end
    
    return nil
end

function entity_die(e, animation)
    if not e then return end
    State.ents[e.tidx] = nil
end

function entity_fall(e)
    if not e then return end
    if e.base.onpit then
        if e.base.onpit(e) then
            return
        end
    end
    
    -- standard fall & die
    -- TODO: fall animation
    State.explosions[e.tidx] = true
    entity_die(e)
end

function entity_set_position(e, x, y)
    local tidx = x
    if y then
        tidx = tidx_of(x, y)
    end
    
    assert(tidx, "entity oob!")
    assert(State.ents[tidx] == nil or State.ents[tidx] == e, "entities would superimpose!")
    
    State.ents[e.tidx] = nil
    State.ents[tidx] = e
    e.tidx = tidx
end

function entity_execute_move(e)
    local x, y = tcoord_of(e.tidx)
    
    assert(e.queued_move, "entity lacks queued move!")
    
    local q = e.queued_move
    if q.move then
        local dstx, dsty = x + q.dx, y + q.dy
        local dstidx = tidx_of(dstx, dsty)
        local movers = State.entity_moving_to[dstidx]
        assert(movers, "never set entity_moving_to before move!")
        if movers and #movers >= 2 then
            entity_die(e)
            State.explosions[dstidx] = true
        else
            if q.crush then
                local crushee = ent_at(dstidx)
                if crushee and crushee ~= e then
                    entity_die(crushee)
                    State.explosions[dstidx] = true
                end
            end

            local srctile = TILES[tile_at(e.tidx) or "void"]
            local dsttile = TILES[tile_at(dstidx) or "wall"]
            if dsttile.pit then
                entity_set_position(e, dstidx)
                entity_fall(e)
            else
                State.tiles_exited[e.tidx] = {e=e, dx=q.dx, dy=q.dy}
                State.tiles_entered[dstidx] = {e=e, dx=q.dx, dy=q.dy}

                -- shade trail propagation
                if e.base.player or e.base.shade then
                    for _, e2 in pairs(State.ents) do
                        if e2.base.shade and entity_facing_tidx(e2) == e.tidx then
                            e2.next_facing = {dx=q.dx, dy=q.dy}
                        end
                    end
                end

                entity_set_position(e, dstx, dsty)
                
                if q.pushed then
                    if e.base.onpush then
                        e.base.onpush(e, q.dx, q.dy)
                    end
                end
            end
        end
    elseif q.blocked == "pdie" then
        add_entity_killing_player(q.e or e)
    elseif q.blocked == "push" then
        -- perform push
        table.insert(State.entity_animating, e)
        e.pushing = true
        q.e.late_queued_move = {
            move=true,
            crush=true,
            pushed=true,
            dx=q.dx, dy=q.dy
        }
    end
    
    e.queued_move = nil
end

function execute_moves()
    State.tiles_entered = {}
    State.tiles_exited = {}
    
    while true do
        -- execute moves
        for tidx, e in pairs(table.copy(State.ents)) do
            if e.queued_move then
                entity_execute_move(e)
            end
        end

        entity_clear_movephase()
        
        -- check if anything to process
        local any_late = false
        
        -- deferred moves
        for tidx, e in pairs(table.copy(State.ents)) do
            if e.late_queued_move then
                e.queued_move = e.late_queued_move
                e.late_queued_move = nil
                local q = e.queued_move
                if q.move then
                    local ex, ey = tcoord_of(e.tidx)
                    local dstx, dsty = ex + q.dx, ey + q.dy
                    add_entity_moving_to(dstx, dsty, e)
                end
                any_late = true
            end
        end
        
        if not any_late then
            break
        end
    end
    
    -- tiles entered/exited
    for tidx, ed in pairs(State.tiles_exited) do
        local e, dx, dy = ed.e, ed.dx, ed.dy
        local tbase = TILES[State.tiles[tidx]]
        if tbase.entity_exit then
            tbase.entity_exit(tidx, e, dx, dy)
        end
    end
    
    for tidx, ed in pairs(State.tiles_entered) do
        local e, dx, dy = ed.e, ed.dx, ed.dy
        local tbase = TILES[State.tiles[tidx]]
        if tbase.entity_enter then
            tbase.entity_enter(tidx, e, dx, dy)
        end
    end
end

function mimics_exist()
    for tidx, e in pairs(State.ents) do
        if e.base.mimic then
            return true
        end
    end
    return false
end

function shades_exist()
    for tidx, e in pairs(State.ents) do
        if e.base.shade then
            return true
        end
    end
    return false
end

ROUND_PHASES = {"shade", "stairs", "mimic", "other", "stairs", "statue"}

function entity_round_phase(e)
    if e.base.shade then
        return "shade"
    elseif e.base.mimic then
        return "mimic"
    elseif e.base.statue then
        return "statue"
    end
    return "other"
end

function phase_has_entities(phase)
    for tidx, e in pairs(State.ents) do
        if entity_round_phase(e) == phase then
            return true
        end
    end
    return false
end

function entities_round(player_dx, player_dy, phase)
    State.shades_advanced = false
    for tidx, e in pairs(table.copy(State.ents)) do
        if entity_round_phase(e) == phase then
            if e.base.update then
                e.base.update(e, player_dx, player_dy)
            end
        end
    end
    
    execute_moves()
end

function lev_zap(e)
    for tidx,e in pairs(State.ents) do
        if e.base.lev then
            table.insert(State.entity_killing_player, e)
        end
    end
    
    pushAction({type="levzap-bolt", t=0, speed=1.0/LEVZAP_BOLT_TIME})
    pushAction({type="levzap-pre", t=0, speed=1.0/LEVZAP_PRE_TIME})
end

function entity_rod_usage(er)
    -- find a statue of lev and activate it
    local any_lev = false
    local all_lev = true
    for x=0,W-1 do
        for y=0,H-1 do
            local e = ent_at(x, y)
            if e and e.base.lev then
                print("lev:", tidx)
                if e.state == "off" then
                    if any_lev then
                        all_lev = false
                    else
                        any_lev = true
                        e.state = "on"
                        e.visible_state = "activate"
                        e.visible_state_t = 0.7
                        e.frame_animation = 0
                        e.frame_animation_speed = 8
                    end
                end
            end
        end
    end
    
    if any_lev and all_lev then
        lev_zap(er)
    end
end