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
        neighbour = tile_at(player_x + input.dx, player_y + input.dy)
        
        if not neighbour then neighbour = "wall" end
        if neighbour.pit then
            pushAction({type="coyote", e=player, dx=input.dx, dy=input.dy, t=0})
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
        action.t += State.action_speed / FPS
        return
    end
    
    actionQueue[#actionQueue] = nil
    
    if action.type == "move" then
        entity_clear_movephase()
        entity_prepare_move(action.e, action.dx, action.dy)
        entity_execute_move(action.e)
    end
end

function playdate.update()
    -- update
    if #actionQueue > 0 then
        processAction()
    elseif queuedInput then
        handleInput(queuedInput)
        queuedInput = nil
        if #actionQueue > 0 then
            processAction()
        end
    end
    
    -- draw
    playdate.graphics.setColor(playdate.graphics.kColorBlack)
    playdate.graphics.fillRect(0, 0, 400, 240)
    draw_tiles()
    draw_entities()
    tick_frame()
end

function playdate.downButtonDown()
    queuedInput = {type="dir", dx=0, dy=1}
end

function playdate.leftButtonDown()
    queuedInput = {type="dir", dx=-1, dy=0}
end

function playdate.rightButtonDown()
    queuedInput = {type="dir", dx=1, dy=0}
end

function playdate.upButtonDown()
    queuedInput = {type="dir", dx=0, dy=-1}
end