K_TEXT_WHITE = 1
K_TEXT_BLACK = 0

function draw_string(px, py, s, flags)
    assert(type(s) == "string")
    flags = flags or K_TEXT_BLACK
    
    if (flags & K_TEXT_WHITE) ~= 0 then
        playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeInverted)
    end
    
    for i=1,#s do
        local c = string.byte(string.sub(s, i, i))
        local t = -1
        
        if c >= string.byte('A') and c <= string.byte('Z') then
            t = c - string.byte('A')
        end
        
        -- TODO: lowercase
        if c >= string.byte('a') and c <= string.byte('z') then
            t = c - string.byte('a')
        end
        
        if c >= string.byte('0') and c <= string.byte('9') then
            t = c - string.byte('0') + 26
        end
        
        if c == string.byte("?") then
            t = 36
        end
        
        if c == string.byte(".") then
            t = 37
        end
        
        if c == string.byte(",") then
            t = 38
        end
        
        if t >= 0 then
            FONT:drawImage(t + 1, px, py)
        end
        
        px += GW/2
    end
    
    playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
end

function draw_gfx(px, py, gfxidx)
    local flip = (gfxidx < 0) and playdate.graphics.kImageFlippedX or nil
    if flip then
        gfxidx *= -1
    end
    GFX:drawImage(gfxidx + 1, px, py, flip)
end

function draw_anim(px, py, anim, f)
    f = f or State.frame_animation
    if type(anim) == "number" then
        draw_gfx(px, py, anim)
        return
    end
    if anim.fast then
        f *= 1.5
    end
    f = math.floor(f)
    f %= #anim
    draw_gfx(px, py, anim[f + 1])
end

function hex(n)
    return string.format("%x", n)
end

function printf(fmt, ...)
    print(string.format(fmt, ...))
end

function cardinal_to_dir(c)
    if c == "n" then
        return 0, -1
    elseif c == "w" then
        return -1, 0
    elseif c == "e" then
        return 1, 0
    else
        return 0, 1
    end
end

function dir_to_cardinal(dx, dy)
    if dx == 1 then
        return "e"
    elseif dx == -1 then
        return "w"
    elseif dy == -1 then
        return "n"
    else
        return "s"
    end
end

function table.has(t, value)
    for k, v in pairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

function table.ihas(t, value)
    for k, v in ipairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

function table.copy(original)
  if type(original) ~= "table" then
    return original
  end
  local copy = {}
  for k, v in pairs(original) do
    copy[k] = v
  end
  return copy
end

function table.deepcopy(original)
  if type(original) ~= "table" then
    return original
  end
  local copy = {}
  for k, v in pairs(original) do
    copy[k] = table.deepcopy(v)
  end
  return copy
end

function table.empty(t)
    for k, v in pairs(t) do
        return false
    end
    return true
end

local lbuff = nil

function get_offscreen_buffer()
    if not lbuff then
        lbuff = playdate.graphics.image.new(400, 240)
    end
    playdate.graphics.pushContext(lbuff)
    playdate.graphics.clear(playdate.graphics.kColorClear)
    playdate.graphics.popContext()
    return lbuff
end