local buffer = require("doublebuffering")
local gpu = require("driver").load("gpu")
local w,h = gpu.getResolution()

local buf = buffer.getMain()
buf.setBackground(0xAAAAAA)
buf.fill(1,1,w,h," ")
buf.draw()


local xx = w/2
local yy = h/2

local s = 4
local title = "Test"

local objs = {}

for i=1,1024 do
    table.insert(objs, {
        xx=w/2,
        yy=h/2
    })
end

while true do
    for k,v in ipairs(objs) do
        buf.setBackground(0xAAAAAA)
        buf.fill(v.xx,v.yy,s,s/2, " ")
        v.xx = v.xx+math.floor(math.random(-24,24))
        v.yy = v.yy+math.floor(math.random(-24,24))
        while xx+s > w do
            v.xx = v.xx-1
        end
        while math.ceil(yy+(s/2)) > h do
            v.yy = v.yy-1
        end

        while v.xx < 1 do
            v.xx = v.xx+1
        end
        while v.yy < 1 do
            v.yy = v.yy+1
        end


        buf.setBackground(0XFFFFFF)
        buf.setForeground(0X0A0A0A)
        buf.fill(v.xx,v.yy,s,s/2, " ")
        buf.set(math.floor(v.xx+s/2 - string.len(title)/2), v.yy, title)


    end
    buf.draw()

    os.sleep(0)
end