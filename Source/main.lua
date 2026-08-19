import "constants"
import "common"
import "entities"
import "tiles"
import "brane"
import "parse"
import "dialogue"

GlobalState = {
    void = false,
    hp = 7,
    lives = 0,
}

GFX = playdate.graphics.imagetable.new("tiles")
FONT = playdate.graphics.imagetable.new("font")

load_brane("branes/b006")
playdate.display.setRefreshRate(20)

queuedInput = nil
queuedInputFrames = 0
actionQueue = {}

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
        
        if neighbour.pit then
            pushAction({type="coyote", e=player, dx=input.dx, dy=input.dy, t=0, speed=1})
        else
            pushAction({type="move", e=player, dx=input.dx, dy=input.dy})
        end
    elseif input.type == "act" then
        pushAction({type="act"})
    end
end

function player_death()
    local deathFade = pushAction({type="fadeout", speed=1.0/0.9, t=0})
    
    if not GlobalState.void and GlobalState.lives >= 1 then
        pushAction({type="lifeloss", speed=1.0/0.6, t=0})
        deathFade.lifeloss = true
    end
end

function push_secondary_animations()
    local t = 0
    if not table.empty(State.explosions) then
        t = math.max(t, EXPLODE_TIME)
    end
    if #State.entity_killing_player > 0 then
        t = math.max(t, KILLPLAYER_TIME)
    end
    if #State.entity_pushing > 0 then
        t = math.max(t, PUSH_TIME)
    end
    
    if t > 0 then
        -- TODO: different time depending on whether killing (long), explosions (med), or push (short)
        
        pushAction({type="secondary", speed=1.0/t, t=0})
        return true
    end
    
    local player = get_player()
    if not player then
        player_death()
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
    if push_secondary_animations() then
        return
    end

    -- 2 phases if mimics present
    if State.entity_moves_pending == true and mimics_exist() then
        State.entity_moves_pending = 2
        entities_round(State.player_dx, State.player_dy, true)
        push_secondary_animations()
    elseif State.entity_moves_pending then
        State.entity_moves_pending = false
        entities_round(State.player_dx, State.player_dy)
        push_secondary_animations()
    end
end

function processAction()
    if #actionQueue == 0 then
        -- no action to advance, but a round phase may still be owed: the
        -- mimic phase leaves entity_moves_pending set for the nonmimic one
        advance_round_phase()
        return
    end

    local action = actionQueue[#actionQueue]
    
    
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
            for tidx, e in pairs(State.entity_pushing) do
                if not e.frame_animation then
                    e.frame_animation = 0
                end
                e.frame_animation_speed = 10
                local push_anim = "push" .. e.state
                if e.base.anim[push_anim] then
                    e.visible_state = push_anim
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
        local player = get_player()
        player.rod_animation_timer = nil
        State.player_dx, State.player_dy = 0, 0
        local dx, dy = cardinal_to_dir(player.state)
        local x, y = tcoord_of(player.tidx)
        local e = ent_at(x + dx, y + dy)
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
                local tstring, state = tile_at(dstidx) or "wall"
                
                if State.rod_storage and TILES[tstring].pit then
                    -- place in pit
                    State.tiles[dstidx] = State.rod_storage.tstring
                    State.tiles_state[dstidx] = State.rod_storage.state
                    State.rod_storage = nil
                    State.entity_moves_pending = true
                    
                    player.rod_animation_timer = 0.42
                elseif not State.rod_storage and TILES[tstring].roddable then
                    -- pick up tile
                    State.rod_storage = {tstring=tstring, state=state}
                    State.tiles[dstidx] = "void"
                    State.tiles_state[dstidx] = nil
                    
                    State.entity_moves_pending = true
                    player.rod_animation_timer = 0.35
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
        local brane_path = State.path
        reset_state()
        if GlobalState.lives == 0 then
            GlobalState.void = true
        end
        if action.lifeloss then
            GlobalState.lives -= 1
        end
        load_brane(brane_path)
        pushAction({type="fadein", t=0, speed=1.0/0.9, lifeloss=action.lifeloss})
    elseif action.type == "move" then
        State.round += 1
        
        -- animation
        action.e.rod_animation_timer = nil
        
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
    elseif action.type == "secondary" then
        State.explosions = {}
        
        for i, e in ipairs(State.entity_killing_player) do
            e.visible_state = nil
            e.frame_animation = nil
        end
        
        for i, e in ipairs(State.entity_pushing) do
            e.visible_state = nil
            e.frame_animation = nil
        end
        
        if #State.entity_killing_player > 0 then
            local player = get_player()
            entity_die(player)
            State.entity_moves_pending = false
            State.explosions[player.tidx] = true
        end
        
        State.entity_killing_player = {}
        State.entity_pushing = {}
    elseif action.type == "fall-panic" then
        local player = get_player()
        entity_die(player)
        State.explosions[player.tidx] = true
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
    
    advance_round_phase()
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
    elseif action.type == "fadein" or action.type == "fadeout" then
        local fadein = action.type == "fadein"
        local buff = get_offscreen_buffer()
        playdate.graphics.pushContext(buff)
        
        if fadein then
            playdate.graphics.clear(playdate.graphics.kColorBlack)
            playdate.graphics.setColor(playdate.graphics.kColorClear)
        else
            playdate.graphics.setColor(playdate.graphics.kColorBlack)
        end
        local t = action.t
        
        for x=-1,W do
            for y=-1,H do
                if (x + y) % 2 == 0 then
                    local px, py = pcoord_of(x, y)
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
        
        playdate.graphics.popContext()
        buff:draw(0, 0)
    end
end

function draw_explosions()
    for tidx, _ in pairs(State.explosions) do
        px, py = pcoord_of(tidx)
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

function playdate.update()
    -- update
    if in_dialogue() then
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
    
    -- draw
    playdate.graphics.setColor(playdate.graphics.kColorBlack)
    playdate.graphics.fillRect(0, 0, 400, 240)
    draw_tiles()
    draw_explosions()
    draw_entities()
    draw_special_animations()
    draw_dialogue()
    
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