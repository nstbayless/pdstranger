TSTRIDE = 20

TILE_B_VOID = 0
TILE_B_FLOOR = 2
TILE_B_STAIRS = 3
TILE_B_STAIRS_LOCKED = 4
TILE_B_BUTTON = 5
TILE_B_GLASS = 6
TILE_B_GLASS_BROKEN = 7
TILE_B_TRAP = 8
TILE_B_EXPLO = 9
TILE_B_SHADE = 10
TILE_B_DEATH = 11
TILE_B_HUD = 12

TILE_HUD_LOCUST = 13
TILE_HUD_ROD = 14
TILE_HUD_BDN_MEMORY = 15
TILE_HUD_BDN_WINGS = 16
TILE_HUD_BDN_SWORD = 17

TILE_WALL_N = 2*TSTRIDE + 0
TILE_WALL_W = 2*TSTRIDE + 1
TILE_WALL_S = 2*TSTRIDE + 2
TILE_WALL_E = 2*TSTRIDE + 3
TILE_WALL_NW = 2*TSTRIDE + 4
TILE_WALL_NE = 2*TSTRIDE + 5
TILE_WALL_SE = 2*TSTRIDE + 6
TILE_WALL_SW = 2*TSTRIDE + 7
TILE_WALL_N2 = 2*TSTRIDE + 8
TILE_WALL_W2 = 2*TSTRIDE + 9
TILE_WALL_S2 = 2*TSTRIDE + 10
TILE_WALL_E2 = 2*TSTRIDE + 11

TILES = {
    void = {
        sym=" ",
        anim=0,
    },
    
    floor = {
        sym="+",
        anim=2,
    },
    
    stair = {
        sym="/",
        anim={
            on=3,
            off=4,
        },
    },
    
    button = {
        sym="@",
        anim=5,
    },
    
    ice = {
        sym="#",
        anim={
            on=6,
            off=7,
        }
    },
    
    trap = {
        sym="%",
        anim=8,
    },
    
    explo = {
        sym="*",
        anim=9,
    },
    
    shade = {
        sym="$",
        anim=10,
    },
    
    death = {
        sym="!",
        anim=11,
    },
    
    wall = {
        sym={
            ["^"]="n",
            ["v"]="s",
            ["<"]="w",
            [">"]="e",
            
            ["7"]="nw",
            ["9"]="ne",
            ["1"]="sw",
            ["3"]="se",
            
            ["^2"]="n2",
            ["v2"]="s2",
            ["<2"]="w2",
            [">2"]="e2",
            
            ["`"]="wn",
            ["'"]="en",
            [","]="ws",
            ["."]="es",
            
            ["`2"]="wn2",
            ["'2"]="en2",
            [",2"]="ws2",
            [".2"]="es2",
        },
        anim = {
            n=2*TSTRIDE + 0,
            w=2*TSTRIDE + 1,
            s=2*TSTRIDE + 2,
            e=2*TSTRIDE + 3,
            nw=2*TSTRIDE + 4,
            ne=2*TSTRIDE + 5,
            sw=2*TSTRIDE + 6,
            se=2*TSTRIDE + 7,
            n2=2*TSTRIDE + 8,
            w2=2*TSTRIDE + 9,
            s2=2*TSTRIDE + 10,
            e2=2*TSTRIDE + 11,
            wn=2*TSTRIDE + 12,
            en=2*TSTRIDE + 13,
            ws=2*TSTRIDE + 14,
            es=2*TSTRIDE + 15,
            wn2=2*TSTRIDE + 16,
            en2=2*TSTRIDE + 17,
            ws2=2*TSTRIDE + 18,
            es2=2*TSTRIDE + 19,
        }
    },
}

ENTS = {
    stadd = {
        sym = "A",
        push = true,
        anim = TSTRIDE*4 + 0,
    },
    
    steus = {
        sym = "E",
        push = true,
        anim = TSTRIDE*4 + 1,
    },
    
    stbee = {
        sym = "B",
        push = true,
        anim = TSTRIDE*4 + 2,
    },
    
    stmon = {
        sym = "M",
        push = true,
        anim = TSTRIDE*4 + 3,
    },
    
    sttan = {
        sym = "T",
        push = true,
        anim = TSTRIDE*4 + 4,
    },
    
    stgor = {
        sym = "G",
        push = true,
        anim = {off=TSTRIDE*4 + 5, on=TSTRIDE*4 + 6},
    },
    
    stlev = {
        sym = "L",
        push = true,
        anim = {off=TSTRIDE*4 + 7, on=TSTRIDE*4 + 8},
    },
    
    stcif = {
        sym = "C",
        push = true,
        anim = TSTRIDE*4 + 9,
    },
    
    player = {
        sym=":",
        anim = {
            e = {3*TSTRIDE + 0, 3*TSTRIDE + 4},
            w = {3*TSTRIDE + 1, 3*TSTRIDE + 5},
            s = {3*TSTRIDE + 2, 3*TSTRIDE + 6},
            n = {3*TSTRIDE + 3, 3*TSTRIDE + 7},
            ure = 3*TSTRIDE + 8,
            urw = 3*TSTRIDE + 9,
            urs = 3*TSTRIDE + 10,
            urn = 3*TSTRIDE + 11,
            rode = 3*TSTRIDE + 12,
            rodw = 3*TSTRIDE + 13,
            rods = 3*TSTRIDE + 14,
            rodn = 3*TSTRIDE + 15,
        }
    },
    
    egg = {
        sym = "o",
        push=true,
        anim=TSTRIDE*4 + 10,
    },
    
    chest = {
        sym = {
            C="on",
            c="off",
        },
        solid=true,
        anim={on=TSTRIDE*4 + 11, off=TSTRIDE*4 + 12},
    },
    
    leech = {
        sym = {
            e="e",
            w="w",
        },
        enemy=true,
        anim={e={TSTRIDE*5 + 0, TSTRIDE*5 + 1}, w={-TSTRIDE*5 + 0, -TSTRIDE*5 - 1}},
    },
    
    maggot = {
        sym = {
            n="n",
            s="s",
        },
        enemy=true,
        anim={s={TSTRIDE*5 + 2, TSTRIDE*5 + 3}, n={TSTRIDE*5 + 4, TSTRIDE*5 + 5}},
    },
    
    smiler = {
        sym = {
            q="w",
            p="e",
        },
        enemy=true,
        anim={e={TSTRIDE*5 + 6, TSTRIDE*5 + 7}, w={-TSTRIDE*5 - 6, -TSTRIDE*5 - 7}},
    },
    
    beaver = {
        sym = "b",
        enemy=true,
        anim={
            idle=TSTRIDE*5 + 8,
            s={TSTRIDE*5 + 9, TSTRIDE*5 + 10},
            e={TSTRIDE*5 + 11, TSTRIDE*5 + 12},
            w={-TSTRIDE*5 - 11, -TSTRIDE*5 - 12},
            n={TSTRIDE*5 + 13, TSTRIDE*5 + 14},
        },
    },
    
    octahedron = {
        sym = "h",
        enemy=true,
        anim={
            idle={TSTRIDE*6 + 0, TSTRIDE*6 + 1},
            active={TSTRIDE*6 + 2, TSTRIDE*6 + 3, TSTRIDE*6 + 4, TSTRIDE*6 + 5, fast=true},
        },
    },
    
    eye = {
        sym = "e",
        enemy=true,
        anim={TSTRIDE*6 + 6, TSTRIDE*6 + 7},
    },
    
    mimx = {
        sym="x",
        enemy=true,
        mimic=true,
        axis={x=true},
        anim={
            s={TSTRIDE*7 + 0, TSTRIDE*7 + 1},
            n={TSTRIDE*7 + 2, TSTRIDE*7 + 3},
            e={TSTRIDE*7 + 4, TSTRIDE*7 + 5},
            w={-TSTRIDE*7 - 4, -TSTRIDE*7 - 5},
        }
    },
    
    mimy = {
        sym="y",
        enemy=true,
        mimic=true,
        axis={y=true},
        anim={
            s={TSTRIDE*8 + 0, TSTRIDE*8 + 1},
            n={TSTRIDE*8 + 2, TSTRIDE*8 + 3},
            e={TSTRIDE*8 + 4, TSTRIDE*8 + 5},
            w={-TSTRIDE*8 - 4, -TSTRIDE*8 - 5},
        }
    },
    
    mimxy = {
        sym="z",
        enemy=true,
        mimic=true,
        axis={x=true, y=true},
        anim={
            s={TSTRIDE*7 + 6, TSTRIDE*7 + 7},
            n={TSTRIDE*7 + 8, TSTRIDE*7 + 9},
            e={TSTRIDE*7 + 10, TSTRIDE*7 + 11},
            w={-TSTRIDE*7 - 10, -TSTRIDE*7 - 11},
        }
    },
    
    mim = {
        sym="m",
        enemy=true,
        mimic=true,
        axis={},
        anim={
            s={TSTRIDE*8 + 6, TSTRIDE*8 + 7},
            n={TSTRIDE*8 + 8, TSTRIDE*8 + 9},
            e={TSTRIDE*8 + 10, TSTRIDE*8 + 11},
            w={-TSTRIDE*8 - 10, -TSTRIDE*8 - 11},
        }
    },
}

OBJLOOKUP = {
}

-- maps glyph -> (tstring, config)
OBJLOOKUP_BY_GLYPH = {}

for key, tile in pairs(TILES) do
    tile.tile = true
    OBJLOOKUP[key] = tile
end

for key, e in pairs(ENTS) do
    e.entity = true
    OBJLOOKUP[key] = e
end

for key, obj in OBJLOOKUP do
    if type(obj.sym) == "string" then
        OBJLOOKUP_BY_GLYPH[obj.sym]={key=key, config=nil}
    elseif type(obj.sym) == "table" then
        for sym, config in pairs(obj.sym) do
            OBJLOOKUP_BY_GLYPH[sym]={key=key, config=config}
        end
    end
end

W = math.floor(400/24)
H = math.floor(240/24)

-- grid size
GW = 24
GH = 24

FPS = 20