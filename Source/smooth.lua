function collision_at(x, y)
    if x == math.floor(x) and y == math.floor(y) then
        local tstring = tile_at(x, y)
        if TILES[tstring].solid or TILES[tstring].pit then return true end
        
        local e = ent_at(x, y)
        if e and (e.base.solid or e.base.push) then
            return true
        end
        
        return false
    end
    
    for xo=math.floor(x),math.ceil(x) do
        for yo=math.floor(y),math.ceil(y) do
            if collision_at(xo, yo) then
                return true
            end
        end
    end
    
    return false
end

function update_smoothmovement()
    local dx = (playdate.buttonIsPressed( playdate.kButtonRight ) and 1 or 0)
        - (playdate.buttonIsPressed( playdate.kButtonLeft ) and 1 or 0)
    local dy = (playdate.buttonIsPressed( playdate.kButtonDown ) and 1 or 0)
        - (playdate.buttonIsPressed( playdate.kButtonUp ) and 1 or 0)
        
    local player = get_player()
    if not player then return end
    
    if player.visible_state_t then
        return
    end
    
    if dx ~= 0 or dy ~= 0 then
        player.state = dir_to_cardinal(dx, dy)
    end
    
    local idx, idy = cardinal_to_dir(player.state)
        
    if not player.smoothx then
        player.smoothx, player.smoothy=tcoord_of(player.tidx)
    end
    
    dx *= SMOOTH_SPEED/FPS
    dy *= SMOOTH_SPEED/FPS
    
    if not collision_at(player.smoothx + dx, player.smoothy) then
        player.smoothx += dx
    end
    
    if not collision_at(player.smoothx, player.smoothy + dy) then
        player.smoothy += dy
    end
    
    -- update player position
    tx = math.floor(player.smoothx)
    ty = math.floor(player.smoothy)
    player.offx = player.smoothx % 1
    player.offy = player.smoothy % 1
    entity_set_position(player, tx, ty)
    
    -- check stairs
    local pcx, pcy = math.floor(player.smoothx + 0.5), math.floor(player.smoothy + 0.5)
    if tile_at(pcx, pcy) == "stair" then
        print("stair")
        exit_by_stairs()
        return
    end
    
    if queuedInput and queuedInput.type == "act" then
        print("ACT")
        queuedInput = nil
        local e = ent_at(pcx + idx, pcy + idy)
        if e and e.base.interact then
            print("INTERACT")
            e.base.interact(e, player, idx, idy)
        end
    end
end