local api = {}
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

    for x=1,ret.width do
        ret.buffer[x] = {}
        for y=1,ret.height do
            ret.buffer[x][y] = {0,0,0}
        end
    end

    ret.lastbuffer = deepcopy(ret.buffer)

    ret.set = function(x,y,char)
        for i=1,char:len() do

            ret.buffer[x+i-1][y] = {char:sub(i,i),ret.foreground,ret.background}
        end
        ret.dirty = true

    end

    ret.get = function(x,y)
        return ret.buffer[x][y]
    end

    ret.fill = function(sx,sy,ex,ey,char)
        for x=sx,sx+ex-1 do
            for y = sy, sy+ey-1 do
                ret.set(x,y,char)
            end
        end
        ret.dirty = true
    end

    ret.copy = function(sx,sy,ex,ey,dx,dy)
        local tmp = {}
        for x=sx,sx+ex do
            if not tmp[sx] then tmp[sx] = {} end
            for y = sy, sy+ey do
                if not tmp[sy] then tmp[sy] = {} end
                tmp[sx][sy] = ret.get(sx,sy)
            end
        end

        local ssx = dx
        local ssy = dy

        for x=sx,sx+ex do

            for y = sy, sy+ey do
                local ton = tmp[sx][sy]
                ret.setForeground(ton[2])
                ret.setBackground(ton[3])
                ret.set(ssx,ssy,ton[1])
                ssy = ssy+1
            end
            ssx = ssx+1
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

    ret.draw = function(xx,yy)
        if not ret.dirty then return end
        if not xx then xx = 1 end
        if not yy then yy = 1 end
        --print(tostring(xx))
        local group = {}
        local fore = gpu.getForeground()
        local back = gpu.getBackground()

        for x=xx,ret.width+xx-1,1 do
            local bx = ret.buffer[x]
            local lbx = ret.lastbuffer[x]
            for y=yy,ret.height+yy-1,1 do
                local by = bx[y]
                local lby = lbx[y]
                if by[1] ~= lby[1] or by[2] ~= lby[2] or by[3] ~= lby[3]  then


                    if fore ~= by[2] then gpu.setForeground(by[2]);fore = by[2] end
                    if back ~= by[3] then gpu.setBackground(by[3]);back = by[3] end
                    ret.proxy.set(x,y,by[1])
                end
            end
        end

        ret.lastbuffer = deepcopy(ret.buffer)
        ret.dirty = false
    end

    return ret
end


return api