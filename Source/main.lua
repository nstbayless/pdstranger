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
        
        entities_round(action.dx, action.dy)
    elseif action.type == "coyote" then
        -- fall into pit
        action.e.offx = nil
        action.e.offy = nil
        action.e.state = action.e.visible_state
        action.e.visible_state = nil
        local x, y = tcoord_of(action.e.tidx)
        entity_set_position(action.e, x + action.dx, y + action.dy)
    end
    
    -- TODO: if explosions exist, push an explosion animation
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