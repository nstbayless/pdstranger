function TILES.stair.get_animkey()
    return get_stairs_locked() and "off" or "on"
end

function TILES.ice.get_animkey(x, y, tstate)
    if ent_at(x, y) then
        return "off"
    end
    
    return "on"
end

function TILES.button.entity_enter(tidx, e, dx, dy)
    if get_stairs_locked() then
        enqueue_sfx("snd_activate")
    else
        enqueue_sfx("snd_reveal")
    end
end

function TILES.shadeglyph.entity_exit(tidx, e, dx, dy)
    if not e.base.spawnshade then
        return
    end

    if e.base.player then
        -- prime
        State.tiles_state[tidx] = "on"
    end

    if State.tiles_state[tidx] ~= "on" then
        return
    end

    -- wait until last shade
    if shade_faces_tidx(tidx) then
        return
    end

    if ent_at(tidx) then
        return
    end

    State.tiles_state[tidx] = "off"
    add_entity({
        basekey="shade",
        state=dir_to_cardinal(dx, dy),
    }, tidx)
end

function TILES.ice.entity_enter(tidx, e)
    if State.tiles_state[tidx] ~= "on" then
        enqueue_sfx("snd_stepglassfloor")
    end
    State.tiles_state[tidx] = "on"
end

function TILES.ice.entity_exit(tidx, e)
    State.tiles[tidx] = "void"
    State.explosions[tidx] = true
    -- TODO: right sfx for this
    enqueue_sfx("snd_curtain_open")
end

function TILES.trap.entity_enter(tidx, e)
    State.tiles[tidx] = "explo"
    enqueue_sfx("snd_activate")
end

function TILES.explo.pretrigger(tidx)
    -- propagate
    State.tiles_triggered[tidx] = true
    enqueue_sfx("snd_vanish")
    
    local x,y = tcoord_of(tidx)
    for i, dir in ipairs(ADJACENT_DIRS) do
        local dx, dy = dir.dx, dir.dy
        local tidx2 = tidx_of(x + dx, y + dy)
        if tidx2 and State.tiles[tidx2] == State.tiles[tidx] and not State.tiles_triggered[tidx2] then
            TILES[State.tiles[tidx2]].pretrigger(tidx2)
        end
    end
end

function TILES.explo.trigger(tidx)
    State.tiles[tidx] = "void"
    State.tiles_state[tidx] = nil
    
    local e = ent_at(tidx)
    if e then
        entity_fall(e)
    end
end

function TILES.death.trigger(tidx)
    local e = ent_at(tidx)
    if e then
        entity_die(e, "explode")
    end
    
    State.tiles_state[tidx] = nil
end

function TILES.explo.entity_enter(tidx, e)
    State.tiles_triggered[tidx] = true
end

function TILES.death.entity_enter(tidx, e)
    State.tiles_triggered[tidx] = true
    -- FIXME: what's the right sfx?
    enqueue_sfx("snd_vanish")
end

function TILES.stair.rodbox()
    if get_stairs_locked() then
        return TILE_ROD_BOX + TILE_B_STAIRS_LOCKED
    else
        return TILE_ROD_BOX + TILE_B_STAIRS
    end
end

function TILES.wall.cliff(x, y, tstate)
    if string.sub(tstate, #tstate) == "2" then
        return false
    end
    return true
end

function TILES.hud.rodbox(tstate)
    if not tstate then
        return TILE_ROD_BOX + TILE_B_HUD
    elseif tstate == "_locust" then
        return TILE_ROD_BOX + TILE_HUD_LOCUST
    else
        return nil
    end
end

function TILES.hud.onrod(tidx, tstate, action)
    local x, y = tcoord_of(tidx)
    local number = string_to_number(tstate)
    print("hud swap", tstate)
    if number then
        local ntstring, nstate = tile_at(x-1, y)
        if ntstring == "hud" and nstate == "_brane" and State.brane_number and action == "place" then
            number += math.floor(State.brane_number / 100)*100
            if number ~= State.brane_number then
                pushAction({type="fadeout", speed=1.0/0.8, t=0, iris={x=x, y=y}, nextbrane=string.format("branes/b%03d", number)})
            end
        elseif ntstring == "hud" and nstate == "HP" then
            GlobalState.hp = number
            if number == 0 then
                enqueue_sfx("snd_player_damage")
                entity_die(get_player())
            end
        end
    elseif tstate == "_brane" and action == "store" then
        -- TODO -- br nil?
        reset_game()
    end
end

function TILES.void.draw()
    return true
end

function TILES.hud.draw(x, y, tstate)
    local px, py = pcoord_of(x, y)
    draw_gfx(px, py, TILE_B_HUD)
    
    if tstate == "_memento" then
        -- TODO
    elseif tstate == "_locust" then
        draw_gfx(px, py, TILE_HUD_LOCUST)
    elseif tstate == "_brane" then
        if State.brane_number then
            draw_string(px, py, string.format("B%0d", math.floor(State.brane_number/100)%10))
        else
            draw_string(px, py, "B?")
        end
    elseif tstate == "_rod" then
        draw_gfx(px, py, TILE_HUD_ROD)
        if State.rod_storage then
            local rbase = TILES[State.rod_storage.tstring]
            local rstate = State.rod_storage.state
            if type(rbase.rodbox) == "number" then
                draw_gfx(px, py, rbase.rodbox or TILE_ROD_BOX_UNK)
            elseif type(rbase.rodbox) == "function" then
                draw_gfx(px, py, rbase.rodbox(rstate) or TILE_ROD_BOX_UNK)
            else
                draw_gfx(px, py, TILE_ROD_BOX_UNK)
            end
        end
    elseif type(tstate) == "string" then
        draw_string(px, py, tstate)
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
    
    -- custom draw
    if base.draw and base.draw(x, y, tstate) then
        return
    end
    
    local tstatedefault = tstate or "default"
    
    -- draw tile
    local anim = base.anim
    if type(anim) == "number" then
        draw_gfx(px, py, anim)
    elseif type(anim) == "table" then
        if base.get_animkey then
            local key = base.get_animkey(x, y, tstate)
            draw_anim(px, py, anim[key])
        elseif anim[tstatedefault] then
            draw_anim(px, py, anim[tstatedefault])
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