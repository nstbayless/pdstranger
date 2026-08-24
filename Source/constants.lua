-- grid size
GW = 24
GH = 24

GAME_VERSION = 100

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

FALLING_OBJECT_ANIM = {
    TSTRIDE*11 + 0,
    TSTRIDE*11 + 1,
    TSTRIDE*11 + 2,
    TSTRIDE*11 + 3,
}

local unpack=table.unpack

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
        anim={
            default=9,
            trigger={false, 9, superfast=true}
        },
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
        cliff=true,
        sym="!",
        anim={
            default=11,
            trigger={11, 2, superfast=true}
        },
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
    
    guts = {
        solid=true,
        sym={
            ["["]="e",
        },
        
        anim = {
            e=12*TSTRIDE + 0,
        },
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
        memory = "...",
        anim = TSTRIDE*4 + 0,
    },
    
    steus = {
        sym = "E",
        push = true,
        statue = true,
        memory = "My love...",
        anim = TSTRIDE*4 + 1,
    },
    
    stbee = {
        sym = "B",
        push = true,
        statue = true,
        memory = "Got any locusts?",
        anim = TSTRIDE*4 + 2,
        bee = true,
    },
    
    stmon = {
        sym = "M",
        push = true,
        statue = true,
        memory = "Ksi shi shi...",
        killstyle = "gold",
        anim = TSTRIDE*4 + 3,
    },
    
    sttan = {
        sym = "T",
        statue = true,
        push = true,
        memory = "Make them go away...",
        anim = TSTRIDE*4 + 4,
    },
    
    stgor = {
        sym = "G",
        push = true,
        statue = true,
        memory = "How bothersome.",
        anim = {off=TSTRIDE*4 + 5, on=TSTRIDE*4 + 6},
    },
    
    stlev = {
        sym = "L",
        push = true,
        statue = true,
        lev = true,
        memory = "One wrong move and I'll destroy you...",
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
        memory = "...",
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
            
            rode = 8*TSTRIDE + 16,
            rodw = 8*TSTRIDE + 17,
            rods = 8*TSTRIDE + 18,
            rodn = 8*TSTRIDE + 19,
            
            swde = 9*TSTRIDE + 16,
            swdw = 9*TSTRIDE + 17,
            swds = 9*TSTRIDE + 18,
            swdn = 9*TSTRIDE + 19,
            
            flynl = {10*TSTRIDE + 16, 10*TSTRIDE + 17, superfast=true, offx=-GW/2},
            flynr = {-10*TSTRIDE - 16, -10*TSTRIDE - 17, superfast=true, offx=GW/2},
            flysl = {10*TSTRIDE + 16, 10*TSTRIDE + 17, superfast=true, offy=-4, offx=-GW/2},
            flysr = {-10*TSTRIDE - 16, -10*TSTRIDE - 17, superfast=true, offy=-4, offx=GW/2},
            flye = {10*TSTRIDE + 16, 10*TSTRIDE + 18, superfast=true, offx=-GW + 7},
            flyw = {-10*TSTRIDE - 16, -10*TSTRIDE - 18, superfast=true, offx=GW - 7},
            
            pushe = 3*TSTRIDE + 12,
            pushw = 3*TSTRIDE + 13,
            pushs = 3*TSTRIDE + 14,
            pushn = 3*TSTRIDE + 15,
            panic = {3*TSTRIDE + 16, 3*TSTRIDE + 17},
            item = 3*TSTRIDE + 18,
            fall = {11*TSTRIDE + 6, 11*TSTRIDE + 7, unpack(FALLING_OBJECT_ANIM)},
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
        sym = {
            o="idle",
        },
        push=true,
        anim={
            idle={TSTRIDE*4 + 10},
            fall={TSTRIDE*11 + 12, TSTRIDE*11 + 13, unpack(FALLING_OBJECT_ANIM)},
        },
        memory = "Howdy."
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
    
    superchest = {
        solid=true,
        chest=true,
        anim={
            onl=TSTRIDE*4 + 13, offl=TSTRIDE*4 + 15,
            onr=TSTRIDE*4 + 14, offr=TSTRIDE*4 + 16,
            on=TSTRIDE*4 + 17, off=TSTRIDE*4 + 18,
        },
    },
    
    leech = {
        sym = {
            e="e",
            w="w",
        },
        swordable = true,
        enemy=true,
        anim={e={TSTRIDE*5 + 0, TSTRIDE*5 + 1}, w={-TSTRIDE*5 + 0, -TSTRIDE*5 - 1}},
    },
    
    maggot = {
        sym = {
            n="n",
            s="s",
        },
        swordable=true,
        enemy=true,
        anim={s={TSTRIDE*5 + 2, TSTRIDE*5 + 3}, n={TSTRIDE*5 + 4, TSTRIDE*5 + 5}},
    },
    
    smiler = {
        sym = {
            q="w",
            p="e",
        },
        enemy=true,
        swordable=true,
        anim={
            e={TSTRIDE*5 + 6, TSTRIDE*5 + 7}, w={-TSTRIDE*5 - 6, -TSTRIDE*5 - 7},
            fall = {11*TSTRIDE + 8, 11*TSTRIDE + 9, unpack(FALLING_OBJECT_ANIM)},
        },
    },
    
    beaver = {
        sym = "b",
        enemy=true,
        swordable=true,
        anim={
            idle={TSTRIDE*5 + 8, TSTRIDE*5 + 9},
            s={TSTRIDE*5 + 10, TSTRIDE*5 + 11},
            e={TSTRIDE*5 + 12, TSTRIDE*5 + 13},
            w={-TSTRIDE*5 - 12, -TSTRIDE*5 - 13},
            n={TSTRIDE*5 + 14, TSTRIDE*5 + 15},
        },
    },
    
    octahedron = {
        sym = "h",
        enemy=true,
        swordable=true,
        anim={
            idle={TSTRIDE*6 + 0, TSTRIDE*6 + 1},
            active={TSTRIDE*6 + 2, TSTRIDE*6 + 3, TSTRIDE*6 + 4, TSTRIDE*6 + 5, fast=true},
            fall = {11*TSTRIDE + 10, 11*TSTRIDE + 11, unpack(FALLING_OBJECT_ANIM)},
        },
    },
    
    eye = {
        sym = "i",
        enemy=true,
        swordable=true,
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
            pushs=TSTRIDE*7+6,
            pushn=TSTRIDE*7+7,
            pushe=TSTRIDE*7+8,
            pushw=-TSTRIDE*7-8,
            fall={TSTRIDE*7 + 9, TSTRIDE*7 + 10, unpack(FALLING_OBJECT_ANIM)},
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
            pushs=TSTRIDE*8+6,
            pushn=TSTRIDE*8+7,
            pushe=TSTRIDE*8+8,
            pushw=-TSTRIDE*8-8,
            fall={TSTRIDE*8 + 9, TSTRIDE*8 + 10, unpack(FALLING_OBJECT_ANIM)},
        }
    },
    
    mimxy = {
        sym="z",
        enemy=true,
        mimic=true,
        axis={x=true, y=true},
        anim={
            s={TSTRIDE*9 + 0, TSTRIDE*9 + 1},
            n={TSTRIDE*9 + 2, TSTRIDE*9 + 3},
            e={TSTRIDE*9 + 4, TSTRIDE*9 + 5},
            w={-TSTRIDE*9 - 4, -TSTRIDE*9 - 5},
            pushs=TSTRIDE*9+6,
            pushn=TSTRIDE*9+7,
            pushe=TSTRIDE*9+8,
            pushw=-TSTRIDE*9-8,
            fall={TSTRIDE*9 + 9, TSTRIDE*9 + 10, unpack(FALLING_OBJECT_ANIM)},
        }
    },
    
    mim = {
        sym="m",
        enemy=true,
        mimic=true,
        axis={},
        anim={
            s={TSTRIDE*10 + 6, TSTRIDE*10 + 7},
            n={TSTRIDE*10 + 8, TSTRIDE*10 + 9},
            e={TSTRIDE*10 + 10, TSTRIDE*10 + 11},
            w={-TSTRIDE*10 - 10, -TSTRIDE*10 - 11},
            pushs=TSTRIDE*10+6,
            pushn=TSTRIDE*10+7,
            pushe=TSTRIDE*10+8,
            pushw=-TSTRIDE*10-8,
            fall={TSTRIDE*10 + 9, TSTRIDE*10 + 10, unpack(FALLING_OBJECT_ANIM)},
        }
    },
}

ANIM_ZAP = {
    n={TSTRIDE*7 + 12, TSTRIDE*7 + 13, superfast=true},
    e={TSTRIDE*7 + 14, TSTRIDE*7 + 15, superfast=true},
    s={-TSTRIDE*7 - 12, -TSTRIDE*7 - 13, superfast=true},
    w={-TSTRIDE*7 - 14, -TSTRIDE*7 - 15, superfast=true},
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
PUSH_TIME = 0.25

VOIDFADE_TIME = 0.9
LIVEFADE_TIME = 0.4
IRIS_SLOW_TIME = 2.5

LEVZAP_PRE_TIME = 0.9
LEVZAP_BOLT_TIME = 0.6

IDOL_TIME = 1.5

COLOR_CHECKERBOARD = { 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55 }

ADJACENT_DIRS = {{dx=-1, dy=0}, {dx=1, dy=0}, {dy=-1, dx=0}, {dy=1, dx=0}}

FALL_ANIM_RATE = 10

MAX_SFX_CACHED = 32

BURDEN_MEMORY = 1
BURDEN_WINGS = 2
BURDEN_SWORD = 3

WHITE_BRANE = "branes/w001"
WHITEGLITCH_TIME = 45