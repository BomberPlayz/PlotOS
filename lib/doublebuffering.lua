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
    --ret.lastbuffer = {}
    ret.lastgroups = {}
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
        local group = {}
        local fore = gpu.getForeground()
        local back = gpu.getBackground()
        -- for y=yy,ret.height+yy-1,1 do
        -- for x=xx,ret.width+xx-1,1 do


        local drawGroups = {}

        -- a group is a rectangle with the same foreground, background, and character.
        -- it is used to minimize the number of gpu.set() calls and use gpu.fill as much as possible.
        --[[ group exanple with x 10, y 12, width 3, height 2, char a, foreground 0x000000, bg 0xffffff:
        {
            10,12,3,2,"a",0x000000,0xffffff
        }
        ]]--
        -- groups are made by adding rectangles to the group table.


        local function addGroup(x,y,w,h,char,fore,back)
            local group = {x,y,w,h,char,fore,back}
            table.insert(drawGroups,group)
        end

        -- a group is a rectangle with the same foreground, background, and character.
        -- it has width, height, x, and y too.

        for y=yy,ret.height+yy-1,1 do
            for x=xx,ret.width+xx-1,1 do
                local labu = ret.lastbuffer[ret.index(x,y)]
                local lama = ret.buffer[ret.index(x,y)]
                if labu[1] ~= lama[1] or labu[2] ~= lama[2] or labu[3] ~= lama[3] then
                --if true then

                    local char,fore,back = ret.get(x,y)
                    local group = nil
                    if #drawGroups > 0 then
                        group = drawGroups[#drawGroups]
                        if group[6] == fore and group[7] == back and group[5] == char then


                            if x-group[1]+1 > group[3] then
                                group[3] = x-group[1]+1
                            end
                            if y-group[2]+1 > group[4] then
                                group[4] = y-group[2]+1
                            end






                        else
                            group = nil
                        end
                    end
                    if not group then
                        addGroup(x,y,1,1,char,fore,back)
                    end

                end
            end
        end











        local fore = gpu.getForeground()
        local back = gpu.getBackground()


        for i=1,#drawGroups do
           -- print("x: "..drawGroups[i][1].." y: "..drawGroups[i][2].." w: "..drawGroups[i][3].." h: "..drawGroups[i][4].." char: "..drawGroups[i][5].." fore: "..drawGroups[i][6].." back: "..drawGroups[i][7])
           -- gpu.set(1,1,"x: "..drawGroups[i][1].." y: "..drawGroups[i][2].." w: "..drawGroups[i][3].." h: "..drawGroups[i][4].." char: "..drawGroups[i][5].." fore: "..drawGroups[i][6].." back: "..drawGroups[i][7])
            local group = drawGroups[i]


            if fore ~= group[6] then
                gpu.setForeground(group[6])
            end
            if back ~= group[7] then
                gpu.setBackground(group[7])
            end

            fore = group[6]
            back = group[7]
                if group[3] > 4 and group[4] > 2 then
                    gpu.fill(group[1],group[2],group[3],group[4],group[5])
                else
                    --gpu.fill(group[1],group[2],group[3],group[4],group[5])
                    for y=group[2],group[2]+group[4]-1,1 do
                        gpu.set(group[1],y,string.rep(group[5],group[3]))
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