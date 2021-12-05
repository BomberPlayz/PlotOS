local gui = require("gui")
local gpu = require("driver").load("gpu")
local buffering = require("doublebuffering")
local process = require("process")


local w,h = gpu.getResolution()

local buf = buffering.getMain()
local workspace = gui.workspace




local win = gui.window(10,10,75,35,"Task Manager")
local cont = gui.container(0,0,75,35)
win:addChild(cont)
workspace:addChild(win)
workspace._tick()
workspace._draw(buf)

buf.draw()

local avg = {}
local t = 0

local tab = 1

while true do
    t = t+1
    if t >= 15 then
        t = 0
        cont.children = {}
        local bb = gui.button(0,0,25,1,"Tab 1")
        bb.onClick = function()
            tab = 1
        end
        local bb2 = gui.button(26,0,25,1,"Tab 2")
        bb2.onClick = function()
            tab = 2
        end
        cont:addChild(bb)
        cont:addChild(bb2)

        if tab == 1 then
            local allcputime = 0
            local processes = {}

            for k,v in ipairs(process.list()) do
                allcputime = allcputime + v:getAvgCpuTime()
                table.insert(processes, v)
            end
            local mlen = 0
            for k,v in ipairs(processes) do
                local lene = v.name:len()
                if lene > mlen then mlen = lene end



            end
            local i = 0



            for k,v in ipairs(processes) do


                i = i+1
                local p = gui.text(1,i,v.name.." :: "..(math.floor((v:getAvgCpuTime()*1000))).."ms".." :: "..(math.floor(v:getAvgCpuPercentage()*10)/10).."%",0x000000,0xffffff)
                cont:addChild(p)

            end
        elseif tab == 2 then



            local bar = gui.progressbar(4,2,2,4)
            bar.value = 100-process.getIdlePercentage()
            cont:addChild(bar)
        end

    end




    -- gui.click = false
    os.sleep(0)
end