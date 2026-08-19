import "constants"
import "common"
import "entities"
import "tiles"
import "brane"
import "parse"

GFX = playdate.graphics.imagetable.new("tiles")

load_brane("b04")
playdate.display.setRefreshRate(20)

queuedInput = nil
queuedInputFrames = 0
actionQueue = {}

function pushAction(a)
    table.insert(actionQueue, a)
end

function handleInput(input)
    local player = get_entity_by_basekey("player")
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
    end
end

function push_secondary_animations()
    if not table.empty(State.explosions) or #State.entity_killing_player > 0 or #State.entity_pushing > 0 then
        
        -- TODO: different time depending on whether killing (long), explosions (med), or push (short)
        
        pushAction({type="secondary", speed=1.0/SECONDARY_ANIMATIONS_TIME, t=0})
        return true
    end
    return false
end

function player_panic_animation()
    local player = get_entity_by_basekey("player")
    if not player then return end
    player.visible_state = "panic"
    if not player.frame_animation then
        player.frame_animation = 0
        player.frame_animation_speed = 10
    end
end

function processAction()
    if #actionQueue == 0 then
        return
    end
    
    local action = actionQueue[#actionQueue]
    
    if action.t and action.t < 1 then
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
            
            -- player death animation
            if #State.entity_killing_player > 0 then
                player_panic_animation()
            end
        end
        
        return
    end
    
    actionQueue[#actionQueue] = nil
    
    if action.type == "move" then
        State.round += 1
        entity_clear_movephase()
        action.e.state = dir_to_cardinal(action.dx, action.dy)
        entity_prepare_move(action.e, action.dx, action.dy)
        execute_moves()
        
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
            local player = get_entity_by_basekey("player")
            entity_die(player)
            State.entity_moves_pending = false
            State.explosions[player.tidx] = true
        end
        
        State.entity_killing_player = {}
        State.entity_pushing = {}
    elseif action.type == "fall-panic" then
        local player = get_entity_by_basekey("player")
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
    
    if not push_secondary_animations() then
        -- TODO: mimics go first
        
        if State.entity_moves_pending then
            State.entity_moves_pending = false
            entities_round()
            push_secondary_animations() 
        end
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
    if #actionQueue > 0 then
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
    
    queuedInputFrames += 1
    tick_frame()
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