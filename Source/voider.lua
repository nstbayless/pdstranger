VOID_CONDITIONS = {}

function VOID_CONDITIONS.linear(e)
    local y = nil
    local x = nil
    
    local hfail = false
    local vfail = false
    
    for tidx=1,TIDX_MAX do
        if tile_at(tidx) == "floor" then
            local tx, ty = tcoord_of(tidx)
            print(tx, ty)
            if not y then
                y = ty
            else
                if ty ~= y then
                    hfail = true
                end
            end
            
            if not x then
                x = tx
            else
                if tx ~= x then
                    vfail = true
                end
            end
        end
    end
    
    print("fail", vfail, hfail)
    
    return (not vfail) or (not hfail)
end