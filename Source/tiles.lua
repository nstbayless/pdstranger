function TILES.stair.get_animkey()
    return get_stairs_locked() and "off" or "on"
end

function TILES.glass.get_animkey(x, y, tstate)
    if ent_at(x, y) then
        return "off"
    end
    
    return "on"
end

function TILES.glass.draw(x, y)
    if State.tile_visitor_heartbeat == 0 then
        if ent_at(x,y) then
            table.insert(State.particles, {anim=ANIM_GLISTEN, x=x-0.5, y=y-0.5, duration=0.7})
            if not (tile_at(x+1, y+1) == "glass" and ent_at(x+1, y+1)) then
                table.insert(State.particles, {anim=ANIM_GLISTEN_DELAYED, x=x+0.5, y=y+0.5, duration=0.7*1.5})
            end
        end
    end
    
    return false
end

function TILES.button.draw(x, y)
    if State.tile_visitor_heartbeat == 0 and State.time_since_action >= WAIT_TIME_REVEAL_BIG_ANIMATIONS then
        if ent_at(x, y) then
            table.insert(State.particles, {anim=ANIM_BUTTON, x=x-1, y=y-1, duration=0.4, behind=true})
        end
    end
    return false
end

function TILES.explo.get_animkey(x, y, tstate)
    if tstate == "visitor" then
        if State.tile_visitor_heartbeat >= 0.5 then
            return "default"
        end
    end
    
    return tstate
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

function TILES.glass.entity_enter(tidx, e)
    if State.tiles_state[tidx] ~= "on" then
        enqueue_sfx("snd_stepglassfloor")
    end
    State.tiles_state[tidx] = "on"
end

function TILES.glass.entity_exit(tidx, e)
    State.tiles[tidx] = "void"
    State.explosions[tidx] = true
    -- TODO: right sfx for this
    enqueue_sfx("snd_curtain_open")
end

function TILES.glass.oncollision(tidx)
    State.tiles[tidx] = "void"
    State.explosions[tidx] = true
end

function TILES.glass.entity_die(tidx, e, cause)
    if cause ~= "crush" then
        State.tiles[tidx] = "void"
        State.explosions[tidx] = true
    end
end

function TILES.trap.entity_enter(tidx, e)
    State.tiles[tidx] = "explo"
    State.tiles_state[tidx] = "visitor"
    enqueue_sfx("snd_activate")
end

function TILES.trap.init(tidx)
    if ent_at(tidx) then
        State.tiles[tidx] = "explo"
        State.tiles_state[tidx] = "visitor"
    end
end

function TILES.explo.init(tidx)
    if ent_at(tidx) then
        State.tiles_state[tidx] = "visitor"
    end
end

function TILES.trap.oncollision(tidx)
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

function TILES.explo.entity_exit(tidx, e)
    State.tiles_state[tidx] = "default"
end

function TILES.explo.entity_die(tidx, e, cause)
    State.tiles_state[tidx] = "default"
end

function TILES.explo.oncollision(tidx)
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
    elseif string.sub(tstate, 1, 2) == "_i" then
        local burden_idx = string_to_number(tstate.sub(tstate, 3, 3))
        if burden_idx then
            GlobalState.burdens[burden_idx] = action == "place"
        end
    elseif tstate == "_brane" and action == "store" then
        crash_game()
    elseif tstate == "_infty" and action == "store" then
        -- TODO -- crash?
        crash_game()
    elseif tstate == "_rod" and action == "store" then
        -- TODO -- crash?
        crash_game()
    end
end

function TILES.void.draw()
    return true
end

function TILES.hud.draw(x, y, tstate)
    local px, py = pcoord_of(x, y)
    draw_gfx(px, py, TILE_B_HUD)
    
    if tstate == "_memento" then
        local col = has_memento()
        if col == 1 then
            draw_gfx(px, py, TILE_HUD_MEMENTO_TMP)
        elseif col == 2 then
            draw_gfx(px, py, TILE_HUD_MEMENTO)
        end
    elseif tstate == "_locust" then
        draw_gfx(px, py, TILE_HUD_LOCUST)
    elseif tstate == "_i1" then
        draw_gfx(px, py, TILE_HUD_BDN_MEMORY)
    elseif tstate == "_i2" then
        draw_gfx(px, py, TILE_HUD_BDN_WINGS)
    elseif tstate == "_i3" then
        if State.frame % 4 < 2 and sword_usable() then
            playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeInverted)
        end
        draw_gfx(px, py, TILE_HUD_BDN_SWORD)
        playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
    elseif tstate == "_brane" then
        if State.brane_number then
            draw_string(px, py, string.format("B%0d", math.floor(State.brane_number/100)%10))
        else
            draw_string(px, py, "B?")
        end
    elseif tstate == "_rod" then
        if GlobalState.hasrod then
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
        end
    elseif type(tstate) == "string" and not string.startswith(tstate, "_") then
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