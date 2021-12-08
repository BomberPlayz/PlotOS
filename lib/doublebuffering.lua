local api = {}
local w,h = component.gpu.maxResolution()
api.main = nil
api.darkmode = false
api.getMain = function()
    if not api.main then api.new(w,h) end
    return api.main
end

local gpu = require("driver").load("gpu")

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

    ret.index = function(x,y)
        return x + ((y-1)*ret.width)
    end

    for x=1,ret.width do
        for y=1,ret.height do
            ret.buffer[ret.index(x,y)] = {" ",0,0}
        end
    end

    ret.lastbuffer = table.pack(table.unpack(ret.buffer))



    ret.set = function(x,y,char)
        for i=1,char:len() do

            ret.buffer[ret.index(x+i-1,y)] = {char:sub(i,i),math.max(ret.foreground-(darkmode and 0x505050 or 0),0),math.max(ret.background-(darkmode and 0x505050 or 0),0)}
        end
        ret.dirty = true

    end

    ret.get = function(x,y)
        return table.unpack(ret.buffer[ret.index(x,y)])
    end

    ret.fill = function(sx,sy,ex,ey,char)
        for x=sx,sx+ex-1 do
            for y = sy, sy+ey-1 do
                ret.set(x,y,char)
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

        for y=yy,ret.height+yy-1,1 do
            for x=xx,ret.width+xx-1,1 do
                local char,foree,backe = table.unpack(ret.buffer[ret.index(x,y)])

                local lastchar,lastfore,lastback = table.unpack(ret.lastbuffer[ret.index(x,y)])
                if char ~= lastchar or foree ~= lastfore or backe ~= lastback then

                    if foree ~= fore then gpu.setForeground(foree); fore = foree end
                    if backe ~= back then gpu.setBackground(backe); back = backe end
                    if backe == 0x000000 and lastback == 0x000000 and char == " " then
                        -- do nothing
                    else
                        gpu.set(x,y,char)
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