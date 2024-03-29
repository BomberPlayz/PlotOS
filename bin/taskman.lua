local gui = require("gui")
local gpu = require("driver").load("gpu")
local buffering = require("doublebuffering")
local process = require("process")
local fs = require("fs")


local w,h = gpu.getResolution()

local buf = buffering.getMain()
local workspace = gui.workspace




local win,closeButton = gui.window(10,10,75,35,"Task Manager")
local cont = gui.container(0,0,75,35)
win:addChild(cont)
workspace:addChild(win)
workspace._tick()
workspace._draw(buf)

buf.draw()

local avg = {}
local t = 0

local tab = 1

function roundToNearestOneDecimal(num)
    return math.floor(num * 10 + 0.5) / 10
end

local selectedProcess = nil

local startProcessTextbox = gui.textbox(1,35-2,45,1,45,0x000000,0xbcbcbc)

while true do
    if win.closed then break end
    t = t+1
    if t >= 20 then
        t = 0
        cont.children = {}
        local bb = gui.button(0,0,25,1,"Processes")
        bb.onClick = function()
            tab = 1
        end
        local bb2 = gui.button(26,0,25,1,"Performance")
        bb2.onClick = function()
            tab = 2
        end


        cont:addChild(bb,bb2)


        if tab == 1 then

            local killProcessButton = gui.button(75-12-14,35-2,11,1,"Kill Process")
            killProcessButton.onClick = function()
                if selectedProcess then
                    selectedProcess:kill()
                end
            end

            local startProcessButton = gui.button(75-13,35-2,12,1,"Start Process")
            startProcessButton.onClick = function()

                local cmd = startProcessTextbox.text
                if fs.exists("/bin/"..cmd..".lua") then
                    process.load(cmd, "/bin/"..cmd..".lua")
                elseif fs.exists(cmd) then
                    local processName = cmd:match("([^/]+)$")
                    processName = processName:match("(.+)%.")
                    process.load(processName, cmd)
                else
                    startProcessTextbox.text = "File not found"
                end

            end



            cont:addChild(killProcessButton,startProcessButton,startProcessTextbox)


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

            local texts = {}

            local function mate(processes,ni)
                if not ni then ni = 1 end
                for k,v in ipairs(processes) do

                    local na = ni
                    i = i+1
                    local tux = v.name.." :: "..(math.floor((v:getAvgCpuTime()*1000))).."ms".." :: "..(math.floor(v:getAvgCpuPercentage()*10)/10).."%"
                    if na > 1 then
                        na = na-1
                        if k == 1 and processes[k+1] == nil then
                            tux = "╚"..tux
                        elseif k == #processes then
                            tux = "╚"..tux
                        else
                            tux = "╠"..tux
                        end
                    end
                    local p = gui.text(na,i,tux,0x000000,v == selectedProcess and 0xaaaaaa or 0xffffff)
                    function p.onMouseDown()
                        selectedProcess = v
                        p.backColor = 0xbcbcbc
                        p.dirty = true
                        for k,v in ipairs(texts) do
                            v.backColor = 0xffffff
                            v.dirty = true
                        end
                    end

                    table.insert(texts, p)
                    cont:addChild(p)

                    if #v.processes > 0 then
                        mate(v.processes,ni+1)
                    end

                end
            end
            mate(processes)
        elseif tab == 2 then
            local cpuUsagePercentage = roundToNearestOneDecimal(100-process.getAvgIdlePercentage())
            local ramUsagePercentage = roundToNearestOneDecimal(((computer.totalMemory()-computer.freeMemory())/computer.totalMemory())*100)

            local cpuText = gui.text(2,2,"CPU:",0x6666ff,0xffffff)
            local cpuTextPrecentage = gui.text(2,3,cpuUsagePercentage.."%",0x6666ff,0xffffff)
            local cpuUsage = gui.progressBarVertical(2,4,5,29)
            cpuUsage.fillColor = 0x6666ff
            cpuUsage.value = cpuUsagePercentage

            local ramText = gui.text(10,2,"RAM:",0xe311FF,0xffffff)
            local ramTextPrecentage = gui.text(10,3,ramUsagePercentage.."%",0xe311FF,0xffffff)
            local ramUsage = gui.progressBarVertical(10,4,5,29)
            ramUsage.fillColor = 0xe311FF
            ramUsage.value = ramUsagePercentage

            cont:addChild(cpuUsage,ramUsage,cpuText,ramText,cpuTextPrecentage,ramTextPrecentage)
        end

    end
    os.sleep(0)
end