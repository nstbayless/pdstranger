import "common"

dialogueQueue = {}

function in_dialogue()
    return dialogueQueue[1]
end

function push_dialogue(msg, side, speaker)
    table.insert(dialogueQueue, {msg=msg, side=side, speaker=speaker, c=0, l=1})
end

function draw_dialogue_box(x0, y0, w, h)
    local x1 = x0+w-1
    local y1 = y0+h-1
    for x=x0,x1 do
        for y=y0,y1 do
            local dx = 0
            local dy = 0
            if x == x0 then dx = -1 end
            if x == x1 then dx = 1 end
            if y == y0 then dy = -1 end
            if y == y1 then dy = 1 end
            local frame = TILE_DIALOGUE[dx][dy]
            local px, py = pcoord_of(x,y)
            draw_gfx(px, py, frame)
        end
    end
end

function dialogue_word_wrap(d, w)
	if d.lines then return d.lines end

	local lines = {}

	local paragraphs = {}
	local start = 1
	while true do
		local nl = d.msg:find("\n", start, true)
		if not nl then
			table.insert(paragraphs, d.msg:sub(start))
			break
		end
		table.insert(paragraphs, d.msg:sub(start, nl - 1))
		start = nl + 1
	end

	for _, paragraph in ipairs(paragraphs) do
		if paragraph == "" then
			-- preserve empty lines from consecutive newlines
			table.insert(lines, "")
		else
			-- Word-wrap the paragraph to w columns
			local current = {}
			local len = 0
			for word in paragraph:gmatch("[^%s]+") do
				if #current > 0 and len + 1 + #word > w then
					table.insert(lines, table.concat(current, " "))
					current = {}
					len = 0
				end
				if #current > 0 then
					len += 1
				end
				len += #word
				table.insert(current, word)
			end
			if #current > 0 then
				table.insert(lines, table.concat(current, " "))
			end
		end
	end

	d.lines = lines
	return lines
end

function tick_dialogue()
    local d = in_dialogue()
    if not d then return end
    
    dialogue_word_wrap(d, (W-2)*2 + 1)
    if #d.lines > 0 then
        assert(type(d.lines[1]) == "string")
    end
    
    local confirm = false
    if queuedInput then
        confirm = queuedInput.type == "act"
        queuedInput = nil
    end
    
    if d.wait then
        if confirm then
            d.wait = false
            if d.l >= #d.lines then
                table.remove(dialogueQueue, 1)
            else
                d.l += 1
                d.c = 0
            end
        end
    elseif d.c < #d.lines[d.l] then
        d.c += 1
        if d.c == #d.lines[d.l] then
            if #d.lines == d.l then
                d.wait = true
            elseif d.l % 2 == 0 then
                d.wait = true
            else
                -- next line; only reset the cursor when the line advances,
                -- or the finished line draws as an empty substring
                d.l += 1
                d.c = 0
            end
        end
    end
end

function entity_dialogue_side(e)
    if not e then return nil end
    local x,y = tcoord_of(e.tidx)
    
    if y >= H-4 then
        return -1
    end
    return 1
end

function draw_dialogue()
    local d = in_dialogue()
    if not d then return end
    
    local htop = H-3
    if d.side and d.side < 0 then
        htop = 0
    end
    
    draw_dialogue_box(0,htop,W,3)
    
    if not d.lines then return end
    
    local px, py = pcoord_of(0, htop)
    px += 0.5*GW
    py += 0.5*GH
    
    local line_scroll = math.floor((d.l-1) / 2)*2
    for i = line_scroll+1,math.min(d.l, line_scroll+2) do
        local c = d.c
        local line = d.lines[i]
        if i < d.l then
            c = #line
        end
        draw_string(px, py, string.sub(line, 1, c), K_TEXT_WHITE)
        py += GH
    end
    
    if d.wait then
        local prompt = TILE_DIALOGUE.prompt[1 + (math.floor(State.frame / 6) % 2)]
        local px,py = pcoord_of(W-1, H-1)
        draw_gfx(px, py, prompt)
    end
end