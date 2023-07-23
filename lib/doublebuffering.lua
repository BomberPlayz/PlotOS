local api = {}
local gpu = require("driver").load("gpu")
local w,h = gpu.maxResolution()
api.main = nil
api.darkmode = false
api.getMain = function()
    if not api.main then api.new(w,h) end
    return api.main
end

local function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function api.new(w,h,proxy)
    local ret = {}

    if not api.main then api.main = ret end

    local gpu = gpu
    if proxy then gpu = proxy end

    ret.proxy = gpu
    ret.buffer = {}
    --ret.lastbuffer = {}
    --ret.lastgroups = {}
    ret.foreground = 0xffffff
    ret.background = 0x000000
    ret.width = w
    ret.height = h
    ret.dirty = true
    ret.mask = {
        x = 1,
        y = 1,
        w = w,
        h = h
    }

    --p is the opacity
    function ret.calcTransparency(c1,c2,p)
        if p == 1 then return c2 end

        --c1, c2, p are numbers. 0xrrggbb
        local r1,g1,b1 = bit32.extract(c1,16,8),bit32.extract(c1,8,8),bit32.extract(c1,0,8)
        local r2,g2,b2 = bit32.extract(c2,16,8),bit32.extract(c2,8,8),bit32.extract(c2,0,8)

        local r = math.floor((1-p)*r1 + p*r2)
        local g = math.floor((1-p)*g1 + p*g2)
        local b = math.floor((1-p)*b1 + p*b2)
        return bit32.lshift(r, 16) + bit32.lshift(g,8) + b
    end

    function ret.setMask(x,y,w,h)
        if not x then
            ret.mask = {
                x = 0,
                y = 0,
                w = ret.width,
                h = ret.height
            }
            return
        end
        ret.mask = {
            x = x,
            y = y,
            w = w,
            h = h
        }
    end

    ret.index = function(x,y)
        return x + ((y-1)*ret.width)
    end

    for x=1,ret.width do
        for y=1,ret.height do
            ret.buffer[ret.index(x,y)] = {" ",0,0}
        end
    end

    ret.lastbuffer = table.pack(table.unpack(ret.buffer))

    ret.set = function(x,y,char,opacity)

        if x < ret.mask.x or x > ret.mask.x + ret.mask.w - 1 or y < ret.mask.y or y > ret.mask.y + ret.mask.h - 1 then return end

        local chor = char
        for i=1,char:len() do
            local coco = ret.buffer[ret.index(x+i-1,y)]
            if coco == nil then coco = {" ",0,0} end
            local char = char
            if char:len() > 1 then
                char = unicode.sub(chor,i,i)
            end
            ret.buffer[ret.index(x+i-1,y)] = {(opacity or 1) < 1 and char == " " and coco[1] or char,ret.calcTransparency(coco[2],ret.foreground,opacity or 1),ret.calcTransparency(coco[3],ret.background,opacity or 1)}
        end
        ret.dirty = true
    end

    ret.get = function(x,y)
        return table.unpack(ret.buffer[ret.index(x,y)])
    end

    ret.fill = function(sx, sy, ex, ey, char, opacity)

        -- optimization: we make only draw what is in the mask
        sx = math.max(sx, ret.mask.x)
        sy = math.max(sy, ret.mask.y)
        ex = math.min(ex, ret.mask.x + ret.mask.w - sx)
        ey = math.min(ey, ret.mask.y + ret.mask.h - sy)

        local localBuffer = ret.buffer
        local localSet = ret.set

        for x = sx, sx + ex - 1 do
            for y = sy, sy + ey - 1 do
                localSet(x, y, char, opacity)
            end
        end
        ret.dirty = true
    end



    ret.setForeground = function(fore)
        ret.foreground = fore
    end

    ret.setBackground = function(background)
        ret.background = background
    end

    ret.getForeground = function()
        return ret.foreground
    end

    ret.getBackground = function()
        return ret.background
    end

    ret.setResolution = function(w,h)
        ret.width = w
        ret.height = h
        ret.dirty = true
    end

    ret.getResolution = function()
        return ret.width,ret.height
    end

    ret.draw = function(xx,yy)
        if not ret.dirty then return end
        if not xx then xx = 1 end
        if not yy then yy = 1 end
        --print(tostring(xx))
        local fore = gpu.getForeground()
        local back = gpu.getBackground()
        -- for y=yy,ret.height+yy-1,1 do
        -- for x=xx,ret.width+xx-1,1 do
        -- draw efficiently: cache foreground, background color and only change when needed. Also, only draw when the pixel changed.
        -- use lastbuffer too, and only set foreground and background when needed.
        if ret.buffer ~= ret.lastbuffer then
            for y=yy,ret.height+yy-1,1 do
                for x=xx,ret.width+xx-1,1 do
                    local char,foree,backe = table.unpack(ret.buffer[ret.index(x,y)])

                    local lastchar,lastfore,lastback = table.unpack(ret.lastbuffer[ret.index(x,y)])
                    if char ~= lastchar or foree ~= lastfore or backe ~= lastback then


                        if backe == 0x000000 and lastback == 0x000000 and char == " " then
                            -- do nothing
                        else
                            if foree ~= fore then gpu.setForeground(foree); fore = foree end
                            if backe ~= back then gpu.setBackground(backe); back = backe end
                            gpu.set(x,y,char)
                        end
                    end
                end
            end

        end
        --ret.lastgroups = drawGroups
        ret.lastbuffer = table.pack(table.unpack(ret.buffer))

        ret.dirty = false
    end

    ret.destroy = function()
        ret = nil
    end

    return ret
end


return api
