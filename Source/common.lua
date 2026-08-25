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
        
        if c == string.byte("!") then
            t = 39
        end
        
        if c == string.byte("[") then
            t = 40
        end
        
        if c == string.byte("]") then
            t = 41
        end
        
        if c == string.byte("'") then
            t = 42
        end
        
        if t >= 0 then
            FONT:drawImage(t + 1, px, py)
        end
        
        px += GW/2
    end
    
    playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
end

function draw_gfx(px, py, gfxidx, big)
    if not gfxidx then return end
    local flip = (gfxidx < 0) and playdate.graphics.kImageFlippedX or nil
    if flip then
        gfxidx *= -1
    end
    (big and BIGGFX or GFX):drawImage(gfxidx + 1, px, py, flip)
end

function draw_anim(px, py, anim, f)
    if not anim then return end
    f = f or State.frame_animation
    if type(anim) == "number" then
        draw_gfx(px, py, anim)
        return
    end
    if anim.fast then
        f *= 1.5
    end
    if anim.superfast then
        f = State.frame
    end
    f = math.floor(f)
    f %= #anim
    draw_gfx(px + (anim.offx or 0), py + (anim.offy or 0), anim[f + 1], anim.big)
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

function table.shuffle(t, p)
    local n = #t
    for i = n, 2, -1 do
        if p and math.random() > p then
            -- don't swap
        else
            local j = math.random(i)
            t[i], t[j] = t[j], t[i]
        end
    end
    return t
end

function iota(n)
    local t = {}
    for i=1,n do
        table.insert(t, i)
    end
    return t
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

function table.size(t)
    local n = 0
    for k, v in pairs(t) do
        n += 1
    end
    return n
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

function string_to_number(s)
    if type(s) ~= "string" then return nil end
    return tonumber(s)
end

function sign(a)
    if a > 0 then return 1
    elseif a < 0 then return -1
    else return 0 end
end

function string.startswith(s, prefix)
    if #s >= #prefix then
        if string.sub(s, 1, #prefix) == prefix then
            return true
        end
    end
    return false
end

function string.endswith(s, prefix)
    if #s >= #prefix then
        if string.sub(s, #s - #prefix) == prefix then
            return true
        end
    end
    return false
end

function string.split(s, pattern)
    local words = {}

    for word in string.gmatch(s, pattern or "%S+") do
        table.insert(words, word)
    end
    
    return words
end

function string.split_respect_quotes(s, pattern)
    local words = string.split(s, pattern)
    local outwords = {}
    
    local inquote = false
    for i, word in ipairs(words) do
        if not inquote then
            if string.startswith(word, '"') then
                if string.endswith(word, '"') then
                    table.insert(outwords, string.sub(word, 2, #word-1))
                else
                    inquote = true
                    table.insert(outwords, string.sub(word, 2))
                end
            else
                table.insert(outwords, word)
            end
        else
            if string.endswith(word, '"') then
                word = string.sub(word, 1, #word-1)
                inquote = false
            end
            
            outwords[#outwords] = outwords[#outwords] .. " " .. word
        end
    end
    
    return outwords
end

function math.round(x)
    return math.floor(x + 0.5)
end