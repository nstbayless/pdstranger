TSTRIDE = 20

TILE_B_VOID = 0
TILE_CLIFF = 1
TILE_B_FLOOR = 2
TILE_B_STAIRS = 3
TILE_B_STAIRS_LOCKED = 4
TILE_B_BUTTON = 5
TILE_B_ICE = 6
TILE_B_ICE_BROKEN = 7
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

TILE_ROD_BOX = TSTRIDE
TILE_ROD_BOX_UNK = TSTRIDE + 1

TILE_QUESTION = TSTRIDE + 14

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

TILE_DIALOGUE = {
    [-1] = {
        [-1] = TSTRIDE*5 + 16,
        [0] = TSTRIDE*6 + 16,
        [1] = TSTRIDE*7 + 16,
    },
    [0] = {
        [-1] = TSTRIDE*5 + 17,
        [0] = TSTRIDE*6 + 17,
        [1] = TSTRIDE*7 + 17,
    },
    [1] = {
        [-1] = TSTRIDE*5 + 18,
        [0] = TSTRIDE*6 + 18,
        [1] = TSTRIDE*7 + 18,
    },
    
    prompt = {
        TSTRIDE*6 + 19,
        TSTRIDE*7 + 19,
    }
}

TILES = {
    void = {
        sym=" ",
        anim=0,
        transparent=true,
        pit=true,
    },
    
    floor = {
        cliff=true,
        sym="+",
        anim=2,
        rodbox = TILE_ROD_BOX + TILE_B_FLOOR,
        roddable=true,
    },
    
    stair = {
        cliff=true,
        stair=true,
        roddable=true,
        sym="/",
        anim={
            on=3,
            off=4,
        },
    },
    
    button = {
        cliff=true,
        button=true,
        roddable=true,
        rodbox = TILE_ROD_BOX + TILE_B_BUTTON,
        sym="@",
        anim=5,
    },
    
    ice = {
        sym="#",
        ice=true,
        roddable=true,
        rodbox = TILE_ROD_BOX + TILE_B_ICE,
        transparent=true,
        anim={
            on=6,
            off=7,
        }
    },
    
    trap = {
        trap=true,
        rodbox = TILE_ROD_BOX + TILE_B_TRAP,
        roddable=true,
        sym="%",
        anim=8,
    },
    
    explo = {
        explo=true,
        roddable=true,
        rodbox = TILE_ROD_BOX + TILE_B_EXPLO,
        sym="*",
        anim=9,
    },
    
    shadeglyph = {
        shade=true,
        roddable=true,
        cliff=true,
        sym="$",
        anim=10,
        rodbox = TILE_ROD_BOX + TILE_B_SHADE,
    },
    
    death = {
        death=true,
        roddable=true,
        sym="!",
        anim=11,
        rodbox = TILE_ROD_BOX + TILE_B_DEATH,
    },
    
    wall = {
        solid=true,
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
            en=2*TSTRIDE + 12,
            wn=2*TSTRIDE + 13,
            ws=2*TSTRIDE + 14,
            es=2*TSTRIDE + 15,
            wn2=2*TSTRIDE + 16,
            en2=2*TSTRIDE + 17,
            ws2=2*TSTRIDE + 18,
            es2=2*TSTRIDE + 19,
        }
    },
    
    hud = {
        anim = TILE_B_HUD,
        roddable=true,
    }
}

ENTS = {
    stadd = {
        sym = "A",
        push = true,
        statue = true,
        anim = TSTRIDE*4 + 0,
    },
    
    steus = {
        sym = "E",
        push = true,
        statue = true,
        anim = TSTRIDE*4 + 1,
    },
    
    stbee = {
        sym = "B",
        push = true,
        statue = true,
        anim = TSTRIDE*4 + 2,
        bee = true,
    },
    
    stmon = {
        sym = "M",
        push = true,
        statue = true,
        anim = TSTRIDE*4 + 3,
    },
    
    sttan = {
        sym = "T",
        statue = true,
        push = true,
        anim = TSTRIDE*4 + 4,
    },
    
    stgor = {
        sym = "G",
        push = true,
        statue = true,
        anim = {off=TSTRIDE*4 + 5, on=TSTRIDE*4 + 6},
    },
    
    stlev = {
        sym = "L",
        push = true,
        statue = true,
        lev = true,
        anim = {
            off=TSTRIDE*4 + 7, on=TSTRIDE*4 + 8,
            activate = {TSTRIDE*4 + 7, TSTRIDE*4 + 8}
        },
    },
    
    stcif = {
        sym = "C",
        push = true,
        statue = true,
        cif = true,
        anim = TSTRIDE*4 + 9,
    },
    
    player = {
        sym=":",
        player = true,
        spawnshade = true,
        anim = {
            e = {3*TSTRIDE + 0, 3*TSTRIDE + 4},
            w = {3*TSTRIDE + 1, 3*TSTRIDE + 5},
            s = {3*TSTRIDE + 2, 3*TSTRIDE + 6},
            n = {3*TSTRIDE + 3, 3*TSTRIDE + 7},
            ure = 3*TSTRIDE + 8,
            urw = 3*TSTRIDE + 9,
            urs = 3*TSTRIDE + 10,
            urn = 3*TSTRIDE + 11,
            rode = 1*TSTRIDE + 16,
            rodw = 1*TSTRIDE + 17,
            rods = 1*TSTRIDE + 18,
            rodn = 1*TSTRIDE + 19,
            pushe = 3*TSTRIDE + 12,
            pushw = 3*TSTRIDE + 13,
            pushs = 3*TSTRIDE + 14,
            pushn = 3*TSTRIDE + 15,
            panic = {3*TSTRIDE + 16, 3*TSTRIDE + 17},
            item = 3*TSTRIDE + 18,
        }
    },
    
    shade = {
        enemy=true,
        pushblocker=true,
        spawnshade=true,
        shade = true,
        anim = {
            s = {6*TSTRIDE + 8, 6*TSTRIDE + 11},
            n = {6*TSTRIDE + 9, 6*TSTRIDE + 12},
            e = {6*TSTRIDE + 10, 6*TSTRIDE + 13},
            w = {-6*TSTRIDE - 10, -6*TSTRIDE - 13},
        }
    },
    
    egg = {
        sym = "o",
        push=true,
        anim=TSTRIDE*4 + 10,
    },
    
    chest = {
        sym = {
            c="on",
            g="off",
        },
        solid=true,
        chest=true,
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
        sym = "i",
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

ANIM_ZAP = {
    n={TSTRIDE*7 + 12, TSTRIDE*7 + 13, superfast=true},
    e={TSTRIDE*7 + 13, TSTRIDE*7 + 14, superfast=true},
    s={-TSTRIDE*7 - 12, -TSTRIDE*7 - 13, superfast=true},
    w={-TSTRIDE*7 - 13, -TSTRIDE*7 - 14, superfast=true},
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

for key, obj in pairs(OBJLOOKUP) do
    if type(obj.sym) == "string" then
        OBJLOOKUP_BY_GLYPH[obj.sym]={key=key, config=nil}
    elseif type(obj.sym) == "table" then
        for sym, config in pairs(obj.sym) do
            OBJLOOKUP_BY_GLYPH[sym]={key=key, config=config}
        end
    end
end

assert(OBJLOOKUP_BY_GLYPH[' '], "no ' '-gylph registered (void)")

W = math.floor(400/24)
H = math.floor(240/24)

TIDX_MAX = W*H

-- grid size
GW = 24
GH = 24

XOFF = math.floor((400 - (W * GW)) / 2)
YOFF = math.floor((240 - (H * GH)) / 2)

FPS = 20

DEFAULT_ACTION_SPEED = 5.3
MAX_INPUT_QUEUE_FRAMES = 3
MOVE_FLAG_NO_PITS = 1
MOVE_FLAG_NO_PUSH = 2
MOVE_FLAG_IGNORE_PLAYER = 4
MOVE_FLAG_NO_PUSHBLOCKER = 8
MOVE_FLAG_IGNORE_SHADES = 16

-- in seconds
SECONDARY_ANIMATIONS_TIME = 0.6

KILLPLAYER_TIME = 0.7
EXPLODE_TIME = 0.2
PUSH_TIME = 0.2

VOIDFADE_TIME = 0.9
LIVEFADE_TIME = 0.4
IRIS_SLOW_TIME = 2.5

LEVZAP_PRE_TIME = 0.9
LEVZAP_BOLT_TIME = 0.6

COLOR_CHECKERBOARD = { 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55 }