import "constants"

function pathfind(x0, y0, x1, y1, bias)
    bias = bias or "nswe"
    local bias_order = {
    }
    for i=1,#bias do
        local dx, dy = cardinal_to_dir(string.sub(bias, i, i))
        bias_order[i] = {dx, dy}
    end
    
    local function tile_passable(x, y)
        local tidx = x
        if y then
            tidx = tidx_of(x, y)
        end
        if not tidx then return false end
        x, y = tcoord_of(tidx)

        local tstring, state = tile_at(tidx)
        tstring = tstring or "wall"
        if TILES[tstring].solid or TILES[tstring].pit then
            return false
        end
        
        -- ignore entities at source/dest
        if (x == x0 and y == y0) then return true end
        if (x == x1 and y == y1) then return true end
        
        local e = ent_at(x, y)
        if e then return false end
        return true
    end
    
    local srcidx = tidx_of(x0, y0)
    local dstidx = tidx_of(x1, y1)
    
    if not tile_passable(dstidx) then
        return nil
    end

    if srcidx == dstidx then
        return {srcidx}
    end

    local frontier = {srcidx}
    local predecessor= {}
    predecessor[srcidx] = -1 -- dummy
    while #frontier > 0 do
        local tidx = table.remove(frontier, 1)
        local x, y = tcoord_of(tidx)
        for _, offset in ipairs(bias_order) do
            local tidx2 = tidx_of(x + offset[1], y + offset[2])
            if tidx2 and not predecessor[tidx2] and tile_passable(tidx2) then
                table.insert(frontier, tidx2)
                predecessor[tidx2] = tidx
                
                -- check if found exit
                if tidx2 == dstidx then
                    local chain = {}
                    local cur = dstidx
                    while cur ~= srcidx do
                        table.insert(chain, 1, cur)
                        cur = predecessor[cur]
                    end
                    table.insert(chain, 1, srcidx)
                    return chain
                end
            end
        end
    end
    
    return nil
end