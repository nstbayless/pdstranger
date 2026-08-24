import "constants"
import "common"
import "entities"
import "tiles"
import "brane"
import "parse"
import "dialogue"
import "sfx"
import "music"

GlobalState = {
    version = GAME_VERSION,
    void = false,
    whiteglitch = 0,
    hp = 7,
    lives = 2,
    brane = nil,
    burdens = {
        [BURDEN_MEMORY]=false,
        [BURDEN_WINGS]=false,
        [BURDEN_SWORD]=false,
    }
}

GFX = playdate.graphics.imagetable.new("tiles")
FONT = playdate.graphics.imagetable.new("font")

function get_starting_brane()
    for i, arg in ipairs(playdate.argv) do
        if string.startswith(arg, "brane=") then
            return string.sub(arg, #"brane="+1)
        end
    end
    return "branes/b001"
end

function reset_game()
    GlobalState.lives = 0
    GlobalState.hp = 7
    GlobalState.void = false
    GlobalState.brane = get_starting_brane()
    reset_state()
    load_brane(GlobalState.brane)
end

function crash_game()
    music_play("silence", 0)
    State.glitch = true
end

playdate.display.setRefreshRate(FPS)

queuedInput = nil
queuedInputFrames = 0
actionQueue = {}

-- set: sound effects
sfxQueue = {}

local fade_pattern = nil

function pushAction(a)
    table.insert(actionQueue, a)
    return a
end

function handleInput(input)
    local player = get_player()
    if not player then
        return
    end
    
    assert(player.tidx)
    
    local player_x, player_y = tcoord_of(player.tidx)
    
    if input.type == "dir" then
        local neighbour = TILES[tile_at(player_x + input.dx, player_y + input.dy) or "wall"]
        
        if neighbour.pit and (not GlobalState.burdens[BURDEN_WINGS] or player.fly) then
            pushAction({type="coyote", e=player, dx=input.dx, dy=input.dy, t=0, speed=1})
        else
            pushAction({type="move", e=player, dx=input.dx, dy=input.dy})
        end
    elseif input.type == "act" then
        pushAction({type="act", e=player})
    end
end

function player_death(e, cause)
    local t = GlobalState.void and VOIDFADE_TIME or LIVEFADE_TIME
    local deathFade = pushAction({type="fadeout", speed=1.0/t, t=0})
    local x, y = tcoord_of(e.tidx)
    
    -- check for stbee
    local en = ent_at(x, y-1)
    local nloc = getLivesFromHUD()
    if en and en.base.bee and nloc >= 1 and cause == "fall" then
        GlobalState.lives = 0
        if not State.brane_number then
            deathFade.nextbrane = WHITE_BRANE
        else
            deathFade.nextbrane = string.format("branes/b%03d", State.brane_number + nloc)
        end
        deathFade.iris = {x=x,y=y}
        deathFade.speed=1.0/IRIS_SLOW_TIME
        en.flashing = true
        en.visible_state_t = 0.6
        return
    end
    
    if not GlobalState.void and nloc >= 1 then
        GlobalState.lives = nloc
        table.insert(State.icons, {tile=TILE_HUD_LOCUST, x=x, y=y})
        enqueue_sfx("snd_resurrect")
        pushAction({type="lifeloss", speed=1.0/1.5, t=0})
        deathFade.lifeloss = true
    end
    
    deathFade.retry_brane = true
    
    if cause ~= "fall" and not GlobalState.void then
        -- set HP to 0
        GlobalState.hp = 0
        
        -- update HUD
        local tidx = find_tile("hud", "HP")
        if tidx then 
            local x,y = tcoord_of(tidx)
            local ntidx = tidx_of(x + 1, y)
            if ntidx then
                local nt, ntstate = tile_at(ntidx)
                if nt == "hud" then
                    local nloc = string_to_number(ntstate)
                    if nloc then
                        State.tiles_state[ntidx] = "00"
                        return true
                    end
                end
            end
        end
    end
    
    deathFade.voidfade = GlobalState.void
end

function push_secondary_animations()
    local t = 0
    if not table.empty(State.explosions) then
        t = math.max(t, EXPLODE_TIME)
    end
    if #State.entity_killing_player > 0 then
        t = math.max(t, KILLPLAYER_TIME)
    end
    for i, e in ipairs(State.entity_animating) do
        t = math.max(t, PUSH_TIME, e.animation_time or 0)
    end
    
    if t > 0 then
        -- TODO: different time depending on whether killing (long), explosions (med), or push (short)
        
        pushAction({type="secondary", speed=1.0/t, t=0})
        return true
    end
    
    return false
end

function player_panic_animation()
    local player = get_player()
    if not player then return end
    player.visible_state = "panic"
    if not player.frame_animation then
        player.frame_animation = 0
        player.frame_animation_speed = 10
    end
end

function advance_round_phase()
    while true do
        if push_secondary_animations() then
            return
        end

        if not State.entity_moves_pending then
            return
        end

        local i = State.entity_moves_pending
        if i == true then
            i = 1
        end

        -- next phase with anything in it
        local phase = nil
        while i <= #ROUND_PHASES do
            if phase_has_entities(ROUND_PHASES[i]) or string.sub(ROUND_PHASES[i], 1, 1) == "_" then
                phase = ROUND_PHASES[i]
                break
            end
            i += 1
        end

        if not phase then
            State.entity_moves_pending = false
            return
        end

        if phase == "_stairs" then
            -- check if player has reached stairs
            if check_player_reached_stairs() then
                State.entity_moves_pending = false
                exit_by_stairs()
                return
            end
        elseif phase == "_post" then
            -- cleanup (stop flying)
            for tidx, e in pairs(State.ents) do
                if e.fly then
                    local tstring, tstate = tile_at(tidx)
                    if not TILES[tstring].pit then
                        e.fly = false
                    end
                end
            end
        elseif phase == "_tiles" then
            -- activate triggered tiles
            if not table.empty(State.tiles_triggered) then
                pushAction({type="tiles-trigger", t=0, speed=1.0/SECONDARY_ANIMATIONS_TIME})
                -- propagate 
                for tidx, _ in pairs(table.copy(State.tiles_triggered)) do
                    local tbase = TILES[State.tiles[tidx]]
                    if tbase.pretrigger then
                        tbase.pretrigger(tidx)
                    end
                end
            end
        else
            entities_round(State.player_dx, State.player_dy, phase)
        end

        -- shade tail propagation
        if not (phase == "shade" and State.shades_advanced
                and shades_pending()) then
            i += 1
        end

        State.entity_moves_pending = (i <= #ROUND_PHASES) and i or false
    end
end

function applyHUDChanges()
    local nloc = getLivesFromHUD()
    if nloc ~= nil then
        GlobalState.lives = nloc
    end
end

function processAction()
    if #actionQueue == 0 then
        -- no action to advance, but a round phase may still be owed: each
        -- phase leaves entity_moves_pending set for the following
        advance_round_phase()
        return
    end

    local action = actionQueue[#actionQueue]
    
    if not action.logged then
        action.logged = true
        --print("action: ", action.type)
    end
    
    if action.t and action.t < 1 then
        
        -- [[ in-progress actions ]] --
        
        action.t += (action.speed or State.action_speed) / FPS
        action.t = math.min(action.t, 1)
        
        if action.type == "coyote" then
            action.e.offx = action.dx * action.t
            action.e.offy = action.dy * action.t
            action.e.visible_state = dir_to_cardinal(action.dx, action.dy)
            
            -- cancel
            if queuedInput and queuedInput.type == "dir" then
                if queuedInput.dx == -action.dx and queuedInput.dy == -action.dy then
                    queuedInput = nil
                    action.e.offx = nil
                    action.e.offy = nil
                    action.e.visible_state = nil
                    actionQueue[#actionQueue] = nil
                end
            end
        elseif action.type == "fall-panic" then
            player_panic_animation()
        elseif action.type == "levzap-pre" then
            State.levzap = true
        elseif action.type == "tiles-trigger" then
            for tidx, _ in pairs(State.tiles_triggered) do
                State.tiles_state[tidx] = "trigger"
            end
        elseif action.type == "secondary" then
            -- entities killing player
            -- TODO: make it face player if possible
            for tidx, e in pairs(State.entity_killing_player) do
                if not e.frame_animation then
                    e.frame_animation = 0
                end
                e.frame_animation_speed = 10
            end
            
            -- entities pushing
            for tidx, e in pairs(State.entity_animating) do
                if e.pushing then
                    e.pushing = false
                    if not e.frame_animation then
                        e.frame_animation = 0
                    end
                    e.frame_animation_speed = 10
                    local push_anim = "push" .. e.state
                    if e.base.anim[push_anim] then
                        e.visible_state = push_anim
                    end
                end
            end
            
            -- player death animation
            if #State.entity_killing_player > 0 then
                player_panic_animation()
            end
        end
        
        return
    end
    
    -- [[ completed actions ]] --
    
    actionQueue[#actionQueue] = nil
    
    if action.type == "act" then
        local player = action.e
        player.rod_animation_timer = nil
        State.player_dx, State.player_dy = 0, 0
        local dx, dy = cardinal_to_dir(player.state)
        local x, y = tcoord_of(player.tidx)
        local e = ent_at(x + dx, y + dy)
        
        -- end item-get pose
        player.visible_state = nil
        player.visible_state_t = nil
        
        local confusion = false
        if e then
            local result = entity_interact(e, player, dx, dy)
            if not result then
                confusion = true
            elseif result == 2 then
                State.entity_moves_pending = true
            end
        else
            local dstidx = tidx_of(x + dx, y + dy)
            if dstidx then
                local tstring, state = tile_at(dstidx)
                tstring = tstring or "wall"
                
                if State.rod_storage and TILES[tstring].pit and GlobalState.hasrod then
                    -- use rod (place a tile)
                    State.tiles[dstidx] = State.rod_storage.tstring
                    State.tiles_state[dstidx] = State.rod_storage.state
                    
                    State.rod_storage = nil
                    State.entity_moves_pending = true
                    
                    player.rod_animation_timer = 0.42
                    player.rodbasekey = "rod"
                    
                    if TILES[State.tiles[dstidx]].onrod then
                        TILES[State.tiles[dstidx]].onrod(dstidx, State.tiles_state[dstidx], "place")
                    end
                    
                    enqueue_sfx("snd_voidrod_store")
                    entity_rod_usage(player)
                elseif not State.rod_storage and TILES[tstring].roddable and GlobalState.hasrod then
                    -- use rod (pick up tile)
                    State.rod_storage = {tstring=tstring, state=state}
                    State.tiles[dstidx] = "void"
                    State.tiles_state[dstidx] = nil
                    
                    State.entity_moves_pending = true
                    player.rod_animation_timer = 0.35
                    player.rodbasekey = "rod"
                    enqueue_sfx("snd_voidrod_place")
                    
                    if TILES[tstring].onrod then
                        TILES[tstring].onrod(dstidx, state, "store")
                    end
                    
                    entity_rod_usage(player)
                else
                    confusion = true
                end
            else
                confusion = true
            end
        end
        
        if confusion then
            pushAction({type="confused", t=0, speed = 1.0/0.5})
        end
    elseif action.type == "fadeout" then
        -- completed fade out
        local brane_path = action.nextbrane or State.path

        applyHUDChanges()
        
        local chests = action.retry_brane and State.empty_chests or {}
        
        reset_state()
        if GlobalState.lives == 0 and not action.nextbrane then
            GlobalState.void = true
        end
        if action.lifeloss then
            GlobalState.lives -= 1
        end
        if not load_brane(brane_path) then
            if not load_brane(WHITE_BRANE) then
                reset_game()
                return
            end
        end
        if action.retry_brane then
            State.empty_chests = chests
        end
        if GlobalState.hp == 0 then
            GlobalState.hp = 7
            if not State.props.nohud then
                load_hud()
            end
        end
        local iris=nil
        if action.nextbrane then
            local player = get_player()
            if player then
                local player_x, player_y = tcoord_of(player.tidx)
                iris = {x=player_x, y=player_y}
            end
        end
        if not State.props.nosave then
            GlobalState.brane = State.path or GlobalState.brane
            playdate.datastore.write(GlobalState, "save", true)
        end
        pushAction({type="fadein", t=0, speed=action.speed, lifeloss=action.lifeloss, voidfade=action.voidfade, iris=iris})
    elseif action.type == "atone" then
        reset_game()
        pushAction({type="fadein", t=0, speed=0.6, white=true})
    elseif action.type == "move" then
        State.round += 1
        
        -- animation
        action.e.rod_animation_timer = nil
        action.e.visible_state = nil
        action.e.visible_state_t = nil
        
        -- record direction for mimic movement later
        State.player_dx, State.player_dy = action.dx, action.dy
        
        -- change facing
        action.e.state = dir_to_cardinal(action.dx, action.dy)
        
        -- move
        entity_clear_movephase()
        entity_prepare_move(action.e, action.dx, action.dy)
        execute_moves()
        
        -- update entities
        State.entity_moves_pending = true
    elseif action.type == "tiles-trigger" then
        for tidx, _ in pairs(table.copy(State.tiles_triggered)) do
            State.tiles_triggered[tidx] = nil
            local tbase = TILES[State.tiles[tidx]]
            if tbase.trigger then
                tbase.trigger(tidx)
            end
        end
    elseif action.type == "levzap-pre" then
        enqueue_sfx("snd_judgment")
    elseif action.type == "levzap-bolt" then
        for i, e in ipairs(State.entity_killing_player) do
            e.visible_state = nil
            e.frame_animation = nil
        end
        local player = get_player()
        if player then
            entity_die(player, "levzap")
            State.entity_moves_pending = false
            pushAction{type="wait", t=0, speed=1/0.4}
        end
        State.levzap = false
    elseif action.type == "secondary" then
        State.explosions = {}
        
        for i, e in ipairs(State.entity_killing_player) do
            e.visible_state = nil
            e.frame_animation = nil
        end
        
        for i, e in ipairs(table.copy(State.entity_animating)) do
            e.visible_state = nil
            e.frame_animation = nil
            if e.base.on_animation_complete then
                e.base.on_animation_complete(e)
            end
        end
        
        if #State.entity_killing_player > 0 then
            local player = get_player()
            local killstyle = nil
            for _, e in ipairs(State.entity_killing_player) do
                killstyle = killstyle or e.base.killstyle
            end
            if player then
                entity_die(player, killstyle or "attacked")
                State.entity_moves_pending = false
            end
        end
        
        State.entity_killing_player = {}
        State.entity_animating = {}
    elseif action.type == "fall-panic" then
        local player = get_player()
        player.fly = true
        entity_fall(player, true)
    elseif action.type == "coyote" then
        -- fall into pit
        action.e.offx = nil
        action.e.offy = nil
        action.e.state = action.e.visible_state
        action.e.visible_state = nil
        local x, y = tcoord_of(action.e.tidx)
        entity_set_position(action.e, x + action.dx, y + action.dy)
        pushAction({type="fall-panic", t=0, speed=1.0/SECONDARY_ANIMATIONS_TIME})
    end
    
    if #actionQueue == 0 then
        advance_round_phase()
    end
end

function draw_special_animations()
    local action = actionQueue[#actionQueue]
    if not action then return end
    if action.type == "confused" then
        if State.frame % 9 <= 5 then
            local player = get_player()
            if player then
                local px, py = pcoord_of(player.tidx)
                draw_gfx(px, py, TILE_QUESTION)
            end
        end
    elseif action.type == "levzap-bolt" then
        local player = get_player()
        if player then
            local px, py = pcoord_of(player.tidx)
            px += GW/2
            if State.frame % 2 == 0 then
                local t = 1.0 - (State.frame % 7) / 7
                local width = 30*t
                local margin = 8 - t
                playdate.graphics.setPattern(COLOR_CHECKERBOARD)
                playdate.graphics.fillRect(px - width - margin, 0, width*2 + margin*2, py + GH)
                playdate.graphics.setColor(playdate.graphics.kColorWhite)
                playdate.graphics.fillRect(px - width, 0, width*2, py + GH)
            end
        end
    elseif action.type == "atone" then
        if action.t < 0.15 then
            return
        end
        
        local atone_x = 200
        local atone_y = 120
        local player = get_player()
        if player then
            player_x, player_y = tcoord_of(player.tidx)
            if player_y >= H/2 then
                atone_y = 50
            else
                atone_y = 190
            end
        end
        
        local p = action.t*2-1
        if p >= 0 then
            atone_x += (math.random() - math.random())*p*20
            atone_y += (math.random() - math.random())*p*17
        end
        
        local s = "Only a simple memory will remain"
        atone_x -= #s*GW/4
        atone_y -= GH/2
        
        draw_string(atone_x, atone_y, s)
        
    elseif action.type == "fadein" or action.type == "fadeout" then
        local fadein = action.type == "fadein"
        local buff = get_offscreen_buffer()
        playdate.graphics.pushContext(buff)
        
        local t = action.t
        if fadein and action.voidfade then
            playdate.graphics.clear(playdate.graphics.kColorBlack)
            playdate.graphics.setColor(playdate.graphics.kColorClear)
        else
            playdate.graphics.setColor(playdate.graphics.kColorBlack)
        end
        
        if action.iris then
            local radius = math.floor((fadein and t or (1-t)) * math.max(W-1, H-1)) - 0.5
            local px, py = pcoord_of(action.iris.x, action.iris.y)
            px += 0.5*GW
            py += 0.5*GH
            playdate.graphics.fillRect(0, py + GH*radius, 400, 240)
            playdate.graphics.fillRect(px + GW*radius, 0, 400, 240)
            playdate.graphics.fillRect(0, 0, 400, py - GH*radius)
            playdate.graphics.fillRect(0, 0, px - GW*radius, 240)
        else
            if not action.voidfade then
                playdate.graphics.setColor((action.lifeloss or action.white) and playdate.graphics.kColorWhite or playdate.graphics.kColorBlack)
                playdate.graphics.setDitherPattern(fadein and t or (1-t))
                playdate.graphics.fillRect(0, 0, 400, 240)
            else
                for x=-1,W do
                    for y=-1,H do
                        local px, py = pcoord_of(x, y)
                        
                        if not action.voidfade then
                            -- pass
                        else
                            -- void fade
                            if (x + y) % 2 == 0 then
                                local p = math.max(t*2 - y/H, 0)
                                px += 0.5 * GW
                                py += 0.5 * GH
                                playdate.graphics.fillPolygon(
                                    px + p * GW, py,
                                    px, py + p * GH,
                                    px - p * GW, py,
                                    px, py - p * GH
                                )
                            end
                        end
                    end
                end
            end
        end
        
        playdate.graphics.popContext()
        buff:draw(0, 0)
    end
end

function draw_explosions()
    for tidx, anim in pairs(State.explosions) do
        px, py = pcoord_of(tidx)
        
        if type(anim) == "table" then
            draw_anim(px, py, anim)
        else
            -- standard explosion
            px += 0.5 * GW
            py += 0.5 * GH
            
            for i=1,8 + math.random(4) do
                local w = 3 + math.random()*14
                local h = 3 + math.random()*12
                
                local xoff = (math.random() - math.random())*GW
                local yoff = (math.random() - math.random())*GH
                
                playdate.graphics.setColor(
                    (math.random(2) == 1)
                        and playdate.graphics.kColorBlack
                        or playdate.graphics.kColorWhite
                )
                if math.random() > 0.4 then
                    playdate.graphics.setColor(playdate.graphics.kColorXOR)
                end
                playdate.graphics.fillRect(px - w/2 + xoff, py - h/2 + yoff, w, h)
            end
        end
    end
end

function draw_icons()
    if table.empty(State.icons) then return end
    
    if State.frame % 4 >= 2 then
        playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeInverted)
    end
    
    for i, icon in pairs(table.copy(State.icons)) do
        if not icon.t then
            icon.t = 0
        end
        icon.t += 1.0/FPS/IDOL_TIME
        if icon.t >= 1 then
            State.icons[i] = nil
        else
            local y = icon.y - math.min(icon.t, 0.3)*2.5
            local px, py = pcoord_of(icon.x, y)
            
            draw_gfx(px, py, icon.tile)
        end
    end
    
    playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
end

function draw_fallers()
    if table.empty(State.fallers) then return end
    for i, faller in pairs(table.copy(State.fallers)) do
        local frame = math.floor(faller.frame)
        local px, py = pcoord_of(faller.tidx)
        draw_anim(px, py, faller.anim, frame)
        
        faller.frame += 1.0/FPS*FALL_ANIM_RATE
        
        if faller.frame >= #faller.anim then
            State.fallers[i] = nil
        end
    end
end

function draw_glitch_tiles(p)
    p = p or 1
    local buff = get_offscreen_buffer()
    playdate.graphics.pushContext(buff)
    
    local wimg = playdate.graphics.getWorkingImage()
    wimg:draw(0, 0)
    playdate.graphics.popContext(buff)
    
    local t = iota(TIDX_MAX*4)
    table.shuffle(t, p)
    
    for tdst, tsrc in ipairs(t) do
        local psx, psy = pcoord_of(math.floor(tsrc/4))
        psx += (tsrc%2) * GW
        psy += (math.floor(tsrc/2)%2) * GW/2
        
        local pdx, pdy = pcoord_of(math.floor(tdst/4))
        pdx += (tdst%2) * GW/2
        pdy += (math.floor(tdst/2)%2) * GH/2
        
        wimg:draw(pdx, pdy, playdate.graphics.kImageUnflipped, psx, psy, GW/2, GH/2)
    end
end

function enqueue_sfx(name)
    sfxQueue[name] = true
end

function play_queued_sfx()
    if table.empty(sfxQueue) then return end
    for key, v in pairs(sfxQueue) do
        play_sfx(key)
    end
    sfxQueue = {}
end

function game_save()
    
end

function update_whiteglitch()
    if State.props.glitch then
        GlobalState.whiteglitch += 1/FPS/WHITEGLITCH_TIME
    else
        GlobalState.whiteglitch = 0
        return
    end
    
    local p = math.min(GlobalState.whiteglitch, 1)
    
    if p >= 0.5 and p < 0.97 then
        if math.random()*(1-p) < (p-0.5)*0.2 then
            draw_glitch_tiles(0.025*p)
        end
    end
    
    if p >= 1 then
        crash_game()
    end
end

function playdate.update()
    -- update
    if State.glitch then
        -- nothing
    elseif in_dialogue() then
        tick_dialogue()
    elseif #actionQueue > 0 or State.entity_moves_pending then
        processAction()
    elseif queuedInput then
        if queuedInputFrames >= MAX_INPUT_QUEUE_FRAMES then
            queuedInput = nil
        else
            handleInput(queuedInput)
            queuedInput = nil
            if #actionQueue > 0 then
                processAction()
            end
        end
    end
    
    -- audio
    play_queued_sfx()
    music_update()
    
    -- draw
    playdate.graphics.setColor(State.atone and playdate.graphics.kColorWhite or playdate.graphics.kColorBlack)
    playdate.graphics.fillRect(0, 0, 400, 240)
    if not State.levzap and not State.atone then
        draw_tiles()
        if State.props.invert then
            playdate.graphics.setColor(playdate.graphics.kColorXOR)
            playdate.graphics.fillRect(0, 0, 400, 240)
        end
        draw_explosions()
    end
    draw_entities()
    draw_fallers()
    draw_icons()
    draw_special_animations()
    draw_dialogue()
    
    if State.glitch then
        draw_glitch_tiles()
    else
        update_whiteglitch()
    end
    
    queuedInputFrames += 1
    tick_frame()
end

function playdate.AButtonDown()
    queuedInput = {type="act"}
    queuedInputFrames = 0
end

function playdate.downButtonDown()
    queuedInput = {type="dir", dx=0, dy=1}
    queuedInputFrames = 0
end

function playdate.leftButtonDown()
    queuedInput = {type="dir", dx=-1, dy=0}
    queuedInputFrames = 0
end

function playdate.rightButtonDown()
    queuedInput = {type="dir", dx=1, dy=0}
    queuedInputFrames = 0
end

function playdate.upButtonDown()
    queuedInput = {type="dir", dx=0, dy=-1}
    queuedInputFrames = 0
end

--- MAIN ---

for i, arg in ipairs(playdate.argv) do
    if arg == "memory" then
        GlobalState.burdens[BURDEN_MEMORY] = true
    end
    if arg == "wings" then
        GlobalState.burdens[BURDEN_WINGS] = true
    end
    if arg == "sword" then
        GlobalState.burdens[BURDEN_SWORD] = true
    end
end

math.randomseed(playdate.getSecondsSinceEpoch())

-- try loading
local _gs = playdate.datastore.read("save")
if _gs and _gs.brane and #playdate.argv <= 1 then
    _gs.version = GAME_VERSION
    GlobalState = _gs
    print("loading game from " .. GlobalState.brane)
    load_brane(GlobalState.brane)
else
    reset_game()
    GlobalState.hasrod = (not State.brane_number) or State.brane_number >= 3
end