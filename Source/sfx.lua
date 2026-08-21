local sfx_cache = {}

function load_sfx(name)
    if sfx_cache[name] then return sfx_cache[name] end
    
    if table.size(sfx_cache) >= MAX_SFX_CACHED then
        -- evict
        -- TODO: evict smarter than random!
        local to_evict = math.random(table.size(sfx_cache))
        for name, v in pairs(sfx_cache) do
            to_evict -= 1
            if to_evict == 0 then
                sfx_cache[name] = nil
                break
            end
        end
    end
    
    local sfx = playdate.sound.sampleplayer.new(string.format("sfx/%s", name))
    
    if not sfx then return nil end
    
    -- add
    sfx_cache[name] = sfx
    return sfx
end

function play_sfx(name)
    local sfx = load_sfx(name)
    if sfx then
        sfx:play()
    end
end

-- some common sfx to start with
for i, sfx in ipairs {
    "snd_activate", "snd_enemy_explosion", "snd_fall", "snd_player_damage",
    "snd_stairs", "snd_vanish", "snd_voice2", "snd_voidrod_place", "snd_voidrod_store",
} do
    load_sfx(sfx)
end