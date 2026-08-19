import "constants"

function ENTS.octahedron.init(e)
    e.state = "idle" or e.state
end

function ENTS.player.init(e)
    e.state = "s" or e.state
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
    
    local anim = base.anim
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

function get_entity_move_blocker(e, dx, dy)
    local x, y = tcoord_of(e.tidx)
    local dstx, dsty = x + dx, y + dy
    
    local tile = tile_at(dstx, dsty) or "wall"
    
    if tile.solid then
        return "stopped"
    else
        local e2 = ent_at(dstx, dsty)
        if not e2 then
            return nil
        else
            if e2.solid then
                return "stopped"
            elseif e2.push then
                -- TODO -- pushing
            elseif e2.enemy and e.enemy then
                return "stopped"
            elseif e2.enemy and e.player then
                return "pdie"
            elseif e2.player and e.enemy then
                return "pdie"
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
    if not State.entity_moving_to[tidx] then
        State.entity_moving_to[tidx] = {}
    end
    if not table.ihas(State.entity_moving_to, e) then
        table.insert(State.entity_moving_to, e)
    end
end

function entity_prepare_move(e, dx, dy)
    local result = get_entity_move_blocker(e, dx, dy)
    local x, y = tcoord_of(e.tidx)
    local dstx, dsty = x + dx, y + dy
    if result == nil then
        e.queued_move = {move=true, dx=dx, dy=dy}
        add_entity_moving_to(dstx, dsty, e)
    else
        e.queued_move = {blocked=result}
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
    State.ents[e.tidx] = nil
end

function entity_set_position(e, x, y)
    tidx = x
    if y then
        tidx = tidx_of(x, y)
    end
    
    assert(not State.ents[tidx], "entities would superimpose!")
    
    State.ents[tidx] = e
    State.ents[e.tidx] = nil
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
            entity_set_position(e, dstx, dsty)
        end
    else
        if e.base.onblock then
            e.base.onblock(e)
        end
    end
    
    e.queued_move = nil
end