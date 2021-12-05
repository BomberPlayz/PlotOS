local gpu = component.gpu
local process = require("process")
local avg = {}
while true do
    local w,h = gpu.getResolution()


    local allcputime = 0
    local processes = {}

    for k,v in ipairs(process.list()) do
        allcputime = allcputime + v.lastCpuTime
        table.insert(processes, v)
    end
    local mlen = 0
    for k,v in ipairs(processes) do
        local lene = v.name:len()
        if lene > mlen then mlen = lene end



    end
    local i = 0

    for k,v in ipairs(processes) do
        if not avg[v.name] then avg[v.name] = {} end
        table.insert(avg[v.name], v:getCpuPercentage())
        if #avg[v.name] > 16 then
            table.remove(avg[v.name], 1)
        end
        local capav = 0
        for k,_ in ipairs(avg[v.name]) do
            capav = capav+avg[v.name][k]
        end
        capav = (capav/#avg[v.name])
        i = i+1
        local lf = gpu.getForeground()
        local lb = gpu.getBackground()
        gpu.setForeground(0xffffff)
        gpu.setBackground(0x000000)
        gpu.set(w-(mlen+20), i, v.name.." "..tostring(capav).."% :: "..v.status)
        gpu.setForeground(lf)
        gpu.setBackground(lb)
    end
    if not avg["Idle"] then avg["Idle"] = {} end
    table.insert(avg["Idle"], process.getUnusedPercent())
    if #avg["Idle"] > 16 then
        table.remove(avg["Idle"], 1)
    end
    capav = 0
    for k,_ in ipairs(avg["Idle"]) do
        capav = capav+avg["Idle"][k]
    end
    capav = (capav/#avg["Idle"])
    i = i+1
    local lf = gpu.getForeground()
    local lb = gpu.getBackground()
    gpu.setForeground(0xffffff)
    gpu.setBackground(0x000000)
    gpu.set(w-(mlen+20), i, "Idle".." "..tostring(capav).."%")
    gpu.setForeground(lf)
    gpu.setBackground(lb)




    os.sleep(0.25)
end