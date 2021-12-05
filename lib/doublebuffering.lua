local api = {}
local w,h = component.gpu.maxResolution()
api.main = nil

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
    ret.lastbuffer = {}
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

            ret.buffer[ret.index(x+i-1,y)] = {char:sub(i,i),ret.foreground,ret.background}
        end
        ret.dirty = true

    end

    ret.get = function(x,y)
        return ret.buffer[ret.index(x,y)]
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
        local group = {}
        local fore = gpu.getForeground()
        local back = gpu.getBackground()

        for x=xx,ret.width+xx-1,1 do
            for y=yy,ret.height+yy-1,1 do
                local by = ret.buffer[ret.index(x,y)]
                local lby = ret.lastbuffer[ret.index(x,y)]
                if by[1] ~= lby[1] or (by[2] ~= lby[2] and by[1] ~= " ") or by[3] ~= lby[3]  then


                    if fore ~= by[2] then gpu.setForeground(by[2]);fore = by[2] end
                    if back ~= by[3] then gpu.setBackground(by[3]);back = by[3] end
                    ret.proxy.set(x,y,by[1])
                end
            end
        end

        ret.lastbuffer = table.pack(table.unpack(ret.buffer))
        ret.dirty = false
    end

    ret.destroy = function()
        ret = nil
    end

    return ret
end


return api