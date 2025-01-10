local gui = require("newgui")
local process = require("process")
local gpu = require("driver").load("gpu")
local std = require("stdlib")
local fs = require("fs")

function roundToNearestOneDecimal(num)
    return math.floor(num * 10 + 0.5) / 10
end

local w, h = gpu.getResolution()
local tab, lastTab = 1, nil
local t = 1

local window = gui.window(10, 10, 75, 35, { title = "Task Manager" })
window.content.color = 0xcccccc

local procButton = gui.button(0, 1, 25, 1, "Processes")
procButton.color = 0xbbbbbb
procButton.eventbus.on("click", function()
    tab = 1
    t = 20
end)

local perfButton = gui.button(27, 1, 25, 1, "Performance")
perfButton.color = 0xbbbbbb
perfButton.eventbus.on("click", function()
    tab = 2
    t = 20
end)

window.addChild(procButton)
window.addChild(perfButton)

local tinput = gui.textinput(54, 1, 20, 1)
window.addChild(tinput)

local cm = gui.contextmenu({
    {
        text = "Start new process",
        visible = true,
        action = function()
            local win = gui.window(10, 10, 40, 10, { title = "Start new process" })
            win.content.color = 0xcccccc
            local tinp = gui.textinput(1, 1, 18, 1)
            win.addChild(tinp)
            local tbtn = gui.button(40 - 8, 10 - 3, 7, 1, "Start")

            tbtn.eventbus.on("click", function()
                local name = std.str.split(tinp.text, "/")[#std.str.split(tinp.text, "/")]
                -- does it exist tho
                if not fs.exists(tinp.text) then
                    local msgbox = gui.window(10, 10, 40, 10, { title = "Error" })
                    msgbox.addChild(gui.label(1, 1, 40, 10, "File does not exist"))
                    local bat = gui.button(40 - 8, 10 - 3, 7, 1, "OK")
                    bat.eventbus.on("click", function()
                        msgbox.close()
                    end)
                    msgbox.addChild(bat)
                    gui.workspace.addChild(msgbox)
                    win.close()
                    return
                end
                process.load(name, tinp.text)
                win.close()
            end)

            win.addChild(tbtn)

            gui.workspace.addChild(win)
        end
    }
})


local menubar = gui.container(0, 0, 75, 1)
local menubutton = gui.button(0, 0, 10, 1, "Stuff")
menubar.addChild(menubutton)
menubutton.eventbus.on("click", function()
    printk("Clicked")
    cm.updateItems()
    cm.showAt(0, 1)
end)

cm.eventbus.on("item_click", function(item)
    item.action()
end)

window.addChild(menubar)
window.addChild(cm)



gui.workspace.addChild(window)

local function mate(processes, depth, lastElement)
    local ret = ""

    if not depth then depth = 0 end
    for i, v in ipairs(processes) do
        local procStr = v.name ..
            " :: " .. (math.floor((v:getAvgCpuTime() * 1000))) ..
            "ms" .. " :: " .. (math.floor(v:getAvgCpuPercentage() * 1000) / 10) .. "%"

        if depth ~= 0 then
            local sub = lastElement and 0 or 1
            local char = ""

            if i == #processes then
                procStr = char .. (" "):rep(depth - 1 - sub) .. "╚" .. procStr
            else
                procStr = char .. (" "):rep(depth - 1 - sub) .. "╠" .. procStr
            end
        end

        ret = ret .. procStr .. "\n"

        if #v.processes ~= 0 then
            ret = ret .. mate(v.processes, depth + 1, i == #processes)
        end
    end

    return ret
end

local currContainer
local cce = {}



while not window.isClosed do
    if t >= 20 and not window.dragging then
        if tab ~= lastTab then
            if currContainer then window.removeChild(currContainer) end
            currContainer = gui.container(0, 2, window.w, window.h - 2)
            currContainer.color = 0xdddddd
            cce = {}
            window.addChild(currContainer)
        end

        if tab == 1 then
            if tab ~= lastTab then
                cce.procList = cce.procList or gui.label(0, 0, currContainer.w, currContainer.h - 1, "")
                cce.procList.color = 0x000000
                currContainer.addChild(cce.procList)
            end

            cce.procList.text = mate(process.list())
        elseif tab == 2 then
            if tab ~= lastTab then
                cce.cpuLabel = cce.cpuLabel or gui.label(1, 1, 50, 1, "CPU: 0%")
                cce.cpuLabel.color = 0x000000
                currContainer.addChild(cce.cpuLabel)

                cce.cpuBar = cce.cpuBar or gui.progressBar(1, 2, 50, 1, 100)
                cce.cpuBar.progressColor = 0x6666ff
                currContainer.addChild(cce.cpuBar)

                cce.memLabel = cce.memLabel or gui.label(1, 4, 50, 1, "MEM: 0%")
                cce.memLabel.color = 0x000000
                currContainer.addChild(cce.memLabel)

                cce.memBar = cce.memBar or gui.progressBar(1, 5, 50, 1, 100)
                cce.memBar.progressColor = 0xe311FF
                currContainer.addChild(cce.memBar)
            end
            local cpuUsagePercentage = roundToNearestOneDecimal(100 - process.getAvgIdlePercentage())
            local memUsagePercentage = roundToNearestOneDecimal(((computer.totalMemory() - computer.freeMemory()) / computer.totalMemory()) *
                100)

            cce.cpuLabel.text = "CPU: " .. cpuUsagePercentage .. "%"
            cce.cpuBar.setProgress(cpuUsagePercentage)
            cce.memLabel.text = "MEM: " .. memUsagePercentage .. "%"
            cce.memBar.setProgress(memUsagePercentage)
        end
        lastTab = tab
        t = 0
    end
    t = t + 1
    os.sleep()
end
