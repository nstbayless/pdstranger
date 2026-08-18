import "brane"

function draw_gfx(px, py, gfxidx)
    flip = (gfxidx < 0) and playdate.graphics.kImageFlippedX or nil
    if flip then
        gfxidx *= -1
    end
    GFX:drawImage(gfxidx + 1, px, py, flip)
end

function draw_anim(px, py, anim)
    local f = State.frame_animation
    if anim.fast then
        f *= 1.5
    end
    f = math.floor(f)
    f %= #anim
    draw_gfx(px, py, anim[f])
end