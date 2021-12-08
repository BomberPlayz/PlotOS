--[[local gpu = component.gpu
local process = require("process")
local avg = {}
while true do
    local w,h = gpu.getResolution()


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

    local lf = gpu.getForeground()
    local lb = gpu.getBackground()
    gpu.setForeground(0xffffff)
    gpu.setBackground(0x000000)

    gpu.fill(w-(mlen+20),1,w,#processes+3," ")

    gpu.setForeground(lf)
    gpu.setBackground(lb)

    for k,v in ipairs(processes) do


        i = i+1
        local lf = gpu.getForeground()
        local lb = gpu.getBackground()
        gpu.setForeground(0xffffff)
        gpu.setBackground(0x000000)
        gpu.set(w-(mlen+20), i, v.name.." "..tostring(math.floor(v:getAvgCpuPercentage()*10)/10).."% :: "..v.status)
        gpu.setForeground(lf)
        gpu.setBackground(lb)
    end


    i = i+1
    local lf = gpu.getForeground()
    local lb = gpu.getBackground()
    gpu.setForeground(0xffffff)
    gpu.setBackground(0x000000)
    gpu.set(w-(mlen+20), i, "Idle".." "..tostring(math.floor(process.getAvgIdlePercentage()*10)/10).."%")
    gpu.setForeground(lf)
    gpu.setBackground(lb)

    i = i+1
    local lf = gpu.getForeground()
    local lb = gpu.getBackground()
    gpu.setForeground(0xffffff)
    gpu.setBackground(0x000000)
    gpu.set(w-(mlen+20), i, "Mem: "..computer.freeMemory() .. " / "..computer.totalMemory())
    gpu.setForeground(lf)
    gpu.setBackground(lb)






    os.sleep(0.25)
end]]