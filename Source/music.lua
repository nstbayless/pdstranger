MUS = {
    silence={
        path=nil,
        beat=0.62,
    },
    concern={
        path="mus/concern",
        beat=(23.569 - 10.046)/16,
        loopstart=16.829,
        loopend=52.333,
    },
    symphony={
        path="mus/voidsymphony",
        beat=(184.996-167.224)/32,
        loopend=309.467,
        loopstart=127.224,
    },
}

DEFAULT_MUSIC = "silence"
local music = nil

local prevmusdef = nil
local downbeat = 0
local beat = 0 -- beat interval
local startloop, endloop

local subbeatoffset = 0
local beatoffset = 0

-- largest beat number to track
-- multiple of various primes for good modulo behaviour
local BEAT_CAP = 9*8*5*7

local lastbeat = 0

local BUFFER_SIZE = 0.25

local VOLUME = 0.5

function music_get_beat()
    if not music then
        -- FIXME: accumulated floating point error
        return subbeatoffset + beatoffset + playdate.sound.getCurrentTime() / beat
    else
        if not music:isPlaying() then return lastbeat end
        
        lastbeat = subbeatoffset + beatoffset + (music:getOffset() - downbeat) / beat
        
        return lastbeat
    end
end

function music_play(musname, fadetime)
    print(musname)
    musname = musname or DEFAULT_MUSIC
    fadetime = fadetime or 2
    
    local musdef = MUS[musname]
    musdef = musdef or MUS[DEFAULT_MUSIC]
    assert(musdef)
    
    if musdef and prevmusdef and musdef.path == prevmusdef.path then
        prevmusdef = musdef
        return
    end
    
    -- stop previous music
    if music and music:isPlaying() then
        if fadetime <= 0 then
            music:stop()
        else
            music:setVolume(0, 0, fadetime, function(self)
                self:stop()
            end)
        end
    end
    
    prevmusdef = musdef
    
    print(musdef, musdef.path)
    
    downbeat = musdef.downbeat or musdef.loopstart or 0
    beat = musdef.beat
    subbeatoffset = musdef.beatoffset or 0
    
    -- paranoia
    beatoffset = 2 * downbeat / beat
    
    -- correct small error in beat length w.r.t. a distance reference beat
    local alignbeat = musdef.alignbeat or musdef.loopend
    if alignbeat then
        local beatcount = math.abs(alignbeat - downbeat) / beat
        beatcount = math.round(beatcount)
        beat = math.abs(alignbeat - downbeat) / beatcount
    end
    
    if not musdef.path then
        music = nil
    else
        startloop = musdef.loopstart
        endloop = musdef.loopend
        music = playdate.sound.fileplayer.new(musdef.path, BUFFER_SIZE)
        print("music", music)
        if not music then return end
        
        music:setVolume(VOLUME)
        music:play()
        music:setVolume(VOLUME)
    end
end

function music_update()
    if music then
        if not music:isPlaying() then
            music:play()
        end
        
        if startloop and endloop then
            local off = music:getOffset()
            if off and off >= endloop then
                print("music loop")
                music:setOffset(startloop + off - endloop + BUFFER_SIZE)
                beatoffset = beatoffset + (endloop - startloop) / beat
                beatoffset = math.floor(beatoffset) % BEAT_CAP
            end
        end
    end
end

function music_get_beats_per_frame()
    return 1 / (beat * FPS)
end