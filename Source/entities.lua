import "constants"

function ENTS.octahedron.init(e)
    e.state = e.state or "idle"
end

function ENTS.player.init(e)
    e.state = e.state or "s"
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
        table.insert(State.entity_killing_player, e)
    elseif blocker ~= nil then
        -- turn around
        e.state = dir_to_cardinal(-dx, -dy)
    else
        entity_prepare_move(e, dx, dy)
    end
end

ENTS.maggot.update = ENTS.leech.update

function entity_init(e)
    local base = e.base
    if e.base.init then
        e.base.init(e)
    end
end

function draw_entity(e)
    local base = e.base
    local px, py = pcoord_of(e.tidx)
    
    px += (e.offx or 0) * GW
    py += (e.offy or 0) * GH
    
    local anim = base.anim
    if type(anim) == "number" then
        draw_gfx(px, py, anim)
    elseif type(anim) == "table" then
        if anim[1] then
            draw_anim(px, py, anim, e.frame_animation)
        else
            anim = anim[e.visible_state or e.state]
            if anim then
                draw_anim(px, py, anim, e.frame_animation)
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
        MOVE_FLAG_NO_PUSH
    )
    return result == nil
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
            if b2.solid then
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
            elseif b2.enemy and b.player then
                return "pdie", e2
            elseif b2.player and b.enemy then
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

function entity_prepare_move(e, dx, dy)
    local result, result_e = get_entity_move_blocker(e, dx, dy)
    local x, y = tcoord_of(e.tidx)
    local dstx, dsty = x + dx, y + dy
    if result == nil then
        e.queued_move = {move=true, dx=dx, dy=dy}
        add_entity_moving_to(dstx, dsty, e)
    else
        e.queued_move = {blocked=result, e=result_e, dx=dx, dy=dy}
    end
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

            entity_set_position(e, dstx, dsty)
        end
    elseif q.blocked == "push" then
        table.insert(State.entity_pushing, e)
        q.e.late_queued_move = {
            move=true,
            crush=true,
            dx=q.dx, dy=q.dy
        }
    end
    
    e.queued_move = nil
end

function execute_moves()
    while true do
        -- execute move
        for tidx, e in pairs(table.copy(State.ents)) do
            if e.queued_move then
                entity_execute_move(e)
            end
        end
        
        entity_clear_movephase()
        
        -- check if anything to process
        local any_late = false
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
end

function entities_round(player_dx, player_dy)
    State.player_dx = player_dx
    State.player_dy = player_dy
    
    for tidx, e in pairs(table.copy(State.ents)) do
        if e.base.update then
            e.base.update(e)
        end
    end
    
    execute_moves()
end