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
    e.depth = 1
    e.state = e.state or "s"
end

function ENTS.steus.ondeath(e, cause)
    if cause == "fall" then
        State.tiles[e.tidx] = "floor"
        entity_die(e, "explode")
        return true
    end
end

function ENTS.stgor.init(e)
    e.state = e.state or "off"
end

function ENTS.stgor.onpush(e)
    e.state = "on"
    e.flashing = true
    e.visible_state_t = SECONDARY_ANIMATIONS_TIME
    enqueue_sfx("snd_activate")
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
        enqueue_sfx("snd_activate")
        enqueue_sfx("snd_laser")
    end
end

function ENTS.stgor.solid(e)
    return e.state == "on"
end

function ENTS.egg.interact(e)
    if not GlobalState.burdens[BURDEN_MEMORY] then return false end
    
    if State.eggmessage and #State.eggmessage > 0 then
        for i, msg in ipairs(State.eggmessage) do
            push_dialogue(msg, entity_dialogue_side(e))
        end
        
        return true
    else
        local a = State.seed % 0x1000
        local b = math.floor(State.seed / 0x1000)
        while gcd(b, #EGGDIALOGUE) ~= 1 do
            b += 1
        end
        local idx = (a + b*e.entity_idx) % #EGGDIALOGUE
        local msg = EGGDIALOGUE[idx+1]
        print(a, b, #EGGDIALOGUE, msg)
        push_dialogue(msg, entity_dialogue_side(e))
        return true
    end
    
    return false
end

import "voider"

function ENTS.stadd.update(e)
    if not State.voidcondition then return end
    
    if VOID_CONDITIONS[State.voidcondition](e) then
        e.flashing = true
        e.animation_time = 0.85
        table.insert(State.entity_animating, e)
        enqueue_sfx("snd_activate")
    end
end

function ENTS.stadd.on_animation_complete(e)
    entity_die(e, "explode")
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
    enqueue_sfx("snd_activate")
end

function ENTS.sttan.on_animation_complete(e)
    entity_die(e, "explode")
end

function ENTS.stlev.init(e)
    e.state = e.state or "off"
end

function ENTS.stlev.ondeath(e)
    -- transfer to another statue
    if e.state == "on" then
        entity_rod_usage(get_player())
    end
end

function ENTS.player.ondeath(e, cause)
    player_death(e, cause)
end

function ENTS.shade.ondeath(e, cause)
    entity_die(get_player(), "shade")
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
    if dx == 0 and dy == 0 then
        return
    end
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

function draw_wings(px, py, e)
    if e.offx then px += e.offx*GW end
    if e.offy then py += e.offy*GH end
    local state = e.visible_state or e.state
    draw_anim(px, py, e.base.anim["fly" .. state .. "l"])
    draw_anim(px, py, e.base.anim["fly" .. state .. "r"])
    draw_anim(px, py, e.base.anim["fly" .. state])
end

function ENTS.player.draw(e)
    local px, py = pcoord_of(e.tidx)
    
    if e.fly then
        e.fly = false
        if (e.visible_state or e.state) == "s" then
            draw_wings(px, py, e)
            draw_entity(e)
        else
            draw_entity(e)
            draw_wings(px, py, e)
        end
        e.fly = true
        return true
    end
    
    if e.rod_animation_timer then
        e.rod_animation_timer -= 1.0/FPS
        if e.rod_animation_timer <= 0 then
            e.rod_animation_timer = nil
        end
        
        local anim_ur = e.base.anim["ur" .. e.state]
        local anim_rod = e.base.anim[(e.rodbasekey or "rod") .. e.state]
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
        
        -- attack adjacent player
        if math.abs(dst_x - x) + math.abs(dst_y - y) == 1 then
            entity_prepare_move(e, dst_x - x, dst_y - y)
            e.state = "active"
            return
        end
        
        -- pathfind to player's previous location
        path = pathfind(x, y, dst_x - dx, dst_y - dy, e.bias, MOVE_FLAG_IGNORE_OCTAHEDRA)
        
        if not path then
            -- pathfind to player's current location
            path = pathfind(x, y, dst_x, dst_y, e.bias, MOVE_FLAG_IGNORE_OCTAHEDRA)
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
    
    local blocker, e2 = get_entity_move_blocker(
        e, dx, dy,
        MOVE_FLAG_NO_PITS | MOVE_FLAG_NO_PUSH | MOVE_FLAG_IGNORE_SHADES | MOVE_FLAG_IGNORE_PLAYER
    )
    if blocker ~= nil then
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
    
    local los, dx, dy = has_line_of_sight(x, y, player_x, player_y)
    
    if los then
        local blocker = get_entity_move_blocker(
            e, dx, dy,
            MOVE_FLAG_NO_PUSH | MOVE_FLAG_IGNORE_PLAYER
        )
        if blocker == nil then
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
        
        -- attack adjacent player
        if math.abs(player_x - x) + math.abs(player_y - y) == 1 then
            entity_prepare_move(e, dx, dy)
            e.state = dir_to_cardinal(dx, dy)
            return
        end
        
        -- charge toward distant player
        if dx ~= 0 or dy ~= 0 then
            if has_line_of_sight(x, y, player_x, player_y) then
                local blocker = get_entity_move_blocker(
                    e, dx, dy,
                    MOVE_FLAG_NO_PUSH | MOVE_FLAG_NO_PITS
                    | MOVE_FLAG_IGNORE_PLAYER | MOVE_FLAG_IGNORE_SHADES
                )
                if blocker == nil then
                    e.state = dir_to_cardinal(dx, dy)
                end
            end
        end
    end
    
    if e.state ~= "idle" then
        local dx, dy = cardinal_to_dir(e.state)
        
        local blocker, e2 = get_entity_move_blocker(
            e, dx, dy,
            MOVE_FLAG_NO_PUSH | MOVE_FLAG_NO_PITS | MOVE_FLAG_IGNORE_SHADES | MOVE_FLAG_IGNORE_PLAYER
        )
        if blocker then
            e.state = "idle"
        else
            entity_prepare_move(e, dx, dy)
        end
    end
end

function ENTS.mim.interact(e)
    if State.mimicmessage and #State.mimicmessage > 0 then
        for i, msg in ipairs(State.mimicmessage) do
            push_dialogue(msg, entity_dialogue_side(e))
        end
        
        return 1
    else
        local a = State.seed % 0x1000
        local b = math.floor(State.seed / 0x1000)
        while gcd(b, #MIMICDIALOGUE) ~= 1 do
            b += 1
        end
        local idx = (a + b*e.entity_idx) % #MIMICDIALOGUE
        local msg = MIMICDIALOGUE[idx+1]
        print(a, b, #MIMICDIALOGUE, msg)
        push_dialogue(msg, entity_dialogue_side(e))
        return 1
    end
end
ENTS.mimx.interact = ENTS.mim.interact
ENTS.mimy.interact = ENTS.mim.interact
ENTS.mimxy.interact = ENTS.mim.interact

function superchest_redundant(e)
    if e.item == "rod" then
        return GlobalState.hasrod
    end
    
    if e.item == "memory" then
        return GlobalState.burdens[BURDEN_MEMORY]
    end
    
    if e.item == "wings" then
        return GlobalState.burdens[BURDEN_WINGS]
    end
    
    if e.item == "sword" then
        return GlobalState.burdens[BURDEN_SWORD]
    end
    
    return true
end

local superchest_messages = {
    rod = {
        {pushaction={type="getrod", t=0, speed=1.0/GETROD_ANIMATION_TIME}},
        "[You acquired a strange rod]",
        "[Simply holding it makes you feel uneasy]",
        "[Something is wrong]",
        {setmusic="concern"},
    },
    memory = {
        "[You acquired a strange feeling]",
        "[Your mind feels heavier]",
        "[... You don't know what to make of it]",
    },
    sword = {
        "[You acquired a strange sword]",
        "[Its ornate design makes it rather cumbersome to use]",
        "[Maybe it will come in handy in the long run]",
    },
    wings = {
        "[You acquired a strange pair of wings]",
        "[They feel extremely brittle]",
        "[Maybe they'll come in handy in the long run]",
    },
}

function ENTS.superchest.init(e)
    e.side = nil
    if e.state == "l" then e.side = "l" end
    if e.state == "r" then e.side = "r" end
    
    e.state = superchest_redundant(e) and "off" or "on"
    
    if e.side then
        e.state = e.state .. e.side
    end
end

function ENTS.chest.bump(e, e2, dx, dy)
    if e.state ~= "on" then return end
    if not e.bumpstate then e.bumpstate = 0 end
    if e.bumpstate ~= "fail" and e.bumpstate ~= "win" then
        e.bumpround = 0
        if dy ~= 1 then
            e.bumpstate = 0
        else
            e.bumpstate += 1
            if e.bumpstate >= 4 then
                e.bumpstate = "fail"
            elseif e.bumpstate == 3 then
                e.bumptime = 0
            end
        end
    end
end

function ENTS.chest.draw(e)
    if e.bumpstate == 3 then
        e.bumptime += 1.0/FPS
        if e.bumptime >= 3 then
            e.flashing = true
            e.visible_state_t = 0.8
            e.bumpstate = "win"
            enqueue_sfx("snd_resurrect")
            e.count = 2 -- yeah just 2 for now
        end
    end
    
    return false
end

function ENTS.chest.update(e, dx, dy)
    if not e.bumpround then return end
    e.bumpround += 1
    if e.bumpround >= 2 then
        e.bumpstate = 0
    end 
end

function ENTS.chest.init(e)
    -- paranoia
    if tile_at(e.tidx) == "void" then
        State.tiles[e.tidx] = "floor"
    end
end

function ENTS.superchest.interact(e, ei, dx, dy)
    if not string.startswith(e.state, "on") then
        return
    else
        local x, y = tcoord_of(e.tidx)
        local e2 = nil
        if e.side == "l" then
            e2 = ent_at(x + 1, y)
        elseif e.side == "r" then
            e2 = ent_at(x - 1, y)
        end
        
        if e2 and e2.basekey == "superchest" then
            e2.state = "off" .. (e2.side or "")
        end
        e.state = "off" .. (e.side or "")
        
        local icon = nil
        
        enqueue_sfx("snd_open")
        
        if e.item == "rod" then
            GlobalState.hasrod = true
            icon = TILE_HUD_ROD
            print("hasrod", GlobalState.hasrod)
        elseif e.item == "memory" then
            GlobalState.burdens[BURDEN_MEMORY] = true
            icon = TILE_HUD_BDN_MEMORY
            local tidx = find_tile("hud", "_ni1")
            if tidx then
                State.tiles_state[tidx] = "_i1"
            end
        elseif e.item == "wings" then
            GlobalState.burdens[BURDEN_WINGS] = true
            icon = TILE_HUD_BDN_WINGS
            local tidx = find_tile("hud", "_ni2")
            if tidx then
                State.tiles_state[tidx] = "_i2"
            end
        elseif e.item == "sword" then
            GlobalState.burdens[BURDEN_SWORD] = true
            icon = TILE_HUD_BDN_SWORD
            local tidx = find_tile("hud", "_ni3")
            if tidx then
                State.tiles_state[tidx] = "_i3"
            end
        end
        
        if icon then
            table.insert(State.particles, {tile=icon, x=x, y=y, invert=true, raise=true})
        end
        
        ei.visible_state_t = IDOL_TIME*1.1
        ei.visible_state = "item"
        ei.state = "s"
        
        for _, message in ipairs(superchest_messages[e.item]) do
            push_dialogue(message, entity_dialogue_side(ei))
        end
        
        return true
    end
end

function ENTS.chest.interact(e, ei, dx, dy)
    if dy == -1 then
        if e.state == "on" then
            e.state = "off"
            local nloc = e.count or 1
            if (State.empty_chests[e.tidx]) then
                nloc = 0
            end
            
            State.empty_chests[e.tidx] = true
            
            enqueue_sfx("snd_activate")
            local ex,ey = tcoord_of(e.tidx)
            if nloc <= 0 then
                push_dialogue("[Empty.]", entity_dialogue_side(get_player()))
            elseif nloc == 1 then
                local success = gainLife()
                
                if not success then
                    push_dialogue("[Huh!? Where did it go..?]", entity_dialogue_side(get_player()))
                else
                    local ex,ey = tcoord_of(e.tidx)
                    table.insert(State.particles, {tile=TILE_HUD_LOCUST, x=ex, y=ey, invert=true, raise=true})
                    if not GlobalState.hasGottenLocust then
                        GlobalState.hasGottenLocust = true
                        if GlobalState.void then
                            push_dialogue("[You found a locust idol!]\n[It looks kind of tasty...]", entity_dialogue_side(get_player()))
                        else
                            push_dialogue("[You found a locust idol!]", entity_dialogue_side(get_player()))
                            push_dialogue("[Perhaps it will come in handy in the long run?]", entity_dialogue_side(get_player()))
                        end
                    end
                end
            else
                local success = gainLife(nloc)
                -- TODO: double locust
                table.insert(State.particles, {tile=TILE_DOUBLE_LOCUST, x=ex, y=ey, invert=true, raise=true})
                if not success then
                    push_dialogue("[Huh!? Where did they go..?]", entity_dialogue_side(get_player()))
                else
                    if not GlobalState.hasGottenLocustLucky then
                        GlobalState.hasGottenLocustLucky = true
                        push_dialogue(string.format("[You found %d locust idols!]", nloc), entity_dialogue_side(get_player()))
                        push_dialogue("[L U C K Y !]", entity_dialogue_side(get_player()))
                        push_dialogue("[What, were you expecting more?]", entity_dialogue_side(get_player()))
                    end
                end
            end
        else
            return false
        end
        
        ei.visible_state_t = IDOL_TIME*1.1
        ei.visible_state = "item"
        ei.state = "s"
        return 1
    end
end

function add_entity_killing_player(e)
    if not e then return end
    if e.base.player then return end
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

function entity_visible(e, depth)
    if depth and depth ~= (e.depth or 0) then return false end
    if State.atone then
        return e.base.cif or e.base.player
    elseif State.levzap then
        return e.base.lev or e.base.player
    else
        return true
    end
end

function draw_entities()
    for depth=0,1 do
        for tidx, e in pairs(State.ents) do
            if e and entity_visible(e, depth) then
                draw_entity(e)
                
                if e.frame_animation then
                    if e.frame_animation_speed then
                        e.frame_animation += e.frame_animation_speed / FPS
                    else 
                        e.frame += music_get_beats_per_frame()
                    end
                end
            end
        end
    end
end

function can_push(e, dx, dy)
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

function entity_canfly(e)
    return e.base.player and not e.fly and GlobalState.burdens[BURDEN_WINGS]
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
                return "stopped", e2
            elseif b2.shade and (flags & MOVE_FLAG_IGNORE_SHADES) ~= 0 then
                return nil
            elseif b2.pushblocker and (flags & MOVE_FLAG_NO_PUSHBLOCKER) ~= 0 then
                return "stopped", e2
            elseif b2.push then
                if (flags & MOVE_FLAG_NO_PUSH) ~= 0 then
                    return "stopped"
                end
                if can_push(e2, dx, dy) then
                    return "push", e2
                else
                    return "stopped", e2
                end
            elseif b2.shade and b.enemy then
                return "pdie", e2
            elseif b2.enemy and b.enemy then
                return "stopped", e2
            elseif b2.enemy and b.player then
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
    elseif e.base.memory and GlobalState.burdens[BURDEN_MEMORY] then
        push_dialogue(e.base.memory, entity_dialogue_side(e))
        return true
    elseif e.base.swordable and GlobalState.burdens[BURDEN_SWORD] then
        entity_die(e, "explode")
        ei.rodbasekey = "swd"
        ei.rod_animation_timer = 0.4
        return 2
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

function entity_die(e, cause)
    if not e then return end
    
    local tstring = tile_at(e.tidx)
    if TILES[tstring] and TILES[tstring].entity_die then
        TILES[tstring].entity_die(e.tidx, e, cause)
    end
    
    if e.base.ondeath then
        if e.base.ondeath(e, cause) then
            return
        end
    end
    
    if cause == "explode" or cause == "crush" then
        State.explosions[e.tidx] = true
        enqueue_sfx(e.base.player and "snd_explosion" or "snd_enemy_explosion")
    end
    
    if cause == "gold" then
        enqueue_sfx("snd_golden")
        -- e.flashing = false
        e.visible_state = nil
        e.visible_state_t = 0
        e.frame_animation_speed = 0
        return
    end
    
    if cause == "fall" then
        local anim = FALLING_OBJECT_ANIM
        if type(e.base.anim) == "table" and e.base.anim.fall then
            anim = e.base.anim.fall
        end
        table.insert(State.fallers, {anim=anim, tidx=e.tidx, frame=0})
        enqueue_sfx(e.base.player and "snd_player_fall" or "snd_fall")
    end
    
    State.ents[e.tidx] = nil
end

function entity_fall(e, skippanic)
    if not e then return end
    
    if not e.fly and entity_canfly(e) then
        e.fly = true
        enqueue_sfx("snd_wingspawn")
        return
    end
    
    e.fly = false
    if e.base.player and not skippanic then
        pushAction({type="fall-panic", t=0, speed=1.0/SECONDARY_ANIMATIONS_TIME})
        return
    end
    
    -- standard fall & die
    entity_die(e, "fall")
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

function entity_execute_push(e)
    local x, y = tcoord_of(e.tidx)
    
    assert(e.queued_move, "entity lacks queued move!")
    local q = e.queued_move
    assert(q.blocked == "push")
    
    -- perform push
    table.insert(State.entity_animating, e)
    e.pushing = true
    
    local epush = q.e
    
    if epush.late_move and epush.late_move.pushed then
        -- already pushed by something else.
        -- cancel the push.
        epush.late_move.move = false
        epush.late_move.dx = 0
        epush.late_move.dy = 0
        enqueue_sfx("snd_push_small")
    else
        -- attempt push
        epush.late_move = {
            move=true,
            pushed=true,
            dx=q.dx, dy=q.dy
        }
    end
    
    -- flying pushers fall
    if e.fly then
        entity_fall(e)
    end
end

function entity_execute_move(e, q)
    local x, y = tcoord_of(e.tidx)
    
    assert(q, "entity lacks queued move!")
    
    if q.move then
        local dstx, dsty = x + q.dx, y + q.dy
        local dstidx = tidx_of(dstx, dsty)
        assert(dstidx, "queued move with invalid dst tile")
        local movers = State.entity_moving_to[dstidx]
        assert(movers, "never set entity_moving_to before move!")
        if movers and #movers >= 2 then
            for i, mover in ipairs(movers) do
                mover.queued_move = nil
                entity_die(mover, "collision")
            end
            
            State.explosions[dstidx] = true
            
            -- kill whatever is there, too
            entity_die(ent_at(dstidx), "collision")
            
            -- then trigger the tile that's there as well
            local tstring = tile_at(dstidx)
            local tile = TILES[tstring]
            if tile and tile.oncollision then
                tile.oncollision(dstidx)
            end
            enqueue_sfx("snd_enemy_explosion")
        else
            if q.pushed then
                enqueue_sfx("snd_push")
                local crushee = ent_at(dstidx)
                if crushee and crushee ~= e then
                    entity_die(crushee, "crush")
                end
            end

            local srcidx = e.tidx
            local srctile = TILES[tile_at(e.tidx) or "void"]
            local dsttile = TILES[tile_at(dstidx) or "wall"]
            
            local pitfall = false
            
            if dsttile.pit then
                if entity_canfly(e) then
                    e.fly = true
                    enqueue_sfx("snd_wingspawn")
                else
                    entity_set_position(e, dstidx)
                    entity_fall(e)
                    pitfall = true
                end
            end
            
            State.tiles_exited[srcidx] = {e=e, dx=q.dx, dy=q.dy}
            
            if not pitfall then
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
        add_entity_killing_player(e)
        add_entity_killing_player(q.e)
        enqueue_sfx("snd_player_damage")
    elseif q.blocked == "stopped" then
        enqueue_sfx("snd_push_small")
        table.insert(State.entity_animating, e)
        if q.e and q.e.base.bump then
            q.e.base.bump(q.e, e, q.dx, q.dy)
        end
        e.pushing = true
        if e.fly then
            entity_fall(e)
        end
    end
    
    e.queued_move = nil
end

function execute_moves()
    State.tiles_entered = {}
    State.tiles_exited = {}
    
    -- collect pushes
    for tidx, e in pairs(table.copy(State.ents)) do
        if e.queued_move and e.queued_move.blocked == "push" then
            entity_execute_push(e)
        end
    end
    
    -- mark pushed entities as moving
    for tidx, e in pairs(table.copy(State.ents)) do
        if e.late_move and e.late_move.pushed and e.late_move.move then
            local x, y = tcoord_of(e.tidx)
            add_entity_moving_to(x + e.late_move.dx, y + e.late_move.dy, e)
        end
    end
    
    -- execute all moves
    for tidx, e in pairs(table.copy(State.ents)) do
        if e.queued_move then
            entity_execute_move(e, e.queued_move)
        end
    end
    
    -- execute late moves
    for tidx, e in pairs(table.copy(State.ents)) do
        if e.late_move then
            entity_execute_move(e, e.late_move)
            e.late_move = nil
        end
    end

    entity_clear_movephase()
    
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

ROUND_PHASES = {"shade", "_stairs", "other", "_stairs", "_tiles", "statue", "_post"}

function entity_round_phase(e)
    if e.base.shade then
        return "shade"
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
    
    enqueue_sfx("snd_activate")
    
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
                if e.state == "off" then
                    enqueue_sfx("snd_activate")
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

function sword_usable()
    local player = get_player()
    if player then
        local x,y = tcoord_of(player.tidx)
        local dx,dy = cardinal_to_dir(player.state)
        
        local e2 = ent_at(x+dx, y+dy)
        if e2 and e2.base.swordable then
            return true
        end
    end
    
    return false
end