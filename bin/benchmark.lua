local buffer = require("doublebuffering")
local gpu = require("driver").load("gpu")
local w,h = gpu.getResolution()

local buf = buffer.new(w,h)
buf.setBackground(0xAAAAAA)
buf.fill(1,1,w,h," ")
buf.draw()


local xx = w/2
local yy = h/2


function textTest()
    buf.setBackground(0xAAAAAA)
    buf.fill(1,1,w,h," ")
    buf.draw()
    local txt = "Benchmark!"
    for i=1,32 do
        for i=1,512 do
            buf.set(math.floor(math.random(1,w-string.len(txt))),math.floor(math.random(1,h)),txt)
        end
        buf.draw()
        os.sleep(0)
    end
end
function fillTest()
    buf.setBackground(0xAAAAAA)
    buf.fill(1,1,w,h," ")
    buf.draw()
    local rndtab = {0xffffff,0xaaaaaa,0x696969,0xbbbbbb,0xff00ff,0x00ff00,0x0000ff,0x00ff00,0xff0000}
    for i=1,16 do
        buf.setBackground(rndtab[math.floor(math.random(1,#rndtab))])
        buf.fill(1,1,w,h," ")
        buf.draw()
        os.sleep(0)
    end
end
function movingTest()
    buf.setBackground(0xAAAAAA)
    buf.fill(1,1,w,h," ")
    buf.draw()
    local objs = {}
    local s = 4
    local title = "Test"

    for i=1,128 do
        table.insert(objs, {
            xx=w/2,
            yy=h/2
        })
    end

    for i=1,16 do

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
end
textTest()
fillTest()
movingTest()