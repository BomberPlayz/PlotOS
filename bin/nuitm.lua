local gui = require("newgui")
local process = require("process")
local gpu = require("driver").load("gpu")

function roundToNearestOneDecimal(num)
    return math.floor(num * 10 + 0.5) / 10
end

local w,h = gpu.getResolution()
local tab, lastTab = 1, nil
local t = 1

local window = gui.window(10,10,75,35)
window.content.color = 0xcccccc

local procButton = gui.button(0,0,25,1,"Processes")
procButton.color = 0xbbbbbb
procButton.eventbus.on("click", function()
	tab = 1
	t = 20
end)

local perfButton = gui.button(27,0,25,1,"Performance")
perfButton.color = 0xbbbbbb
perfButton.eventbus.on("click", function()
	tab = 2
	t = 20
end)

window.addChild(procButton)
window.addChild(perfButton)
gui.workspace.addChild(window)

local currContainer
local cce = {}

while not window.isClosed do
	if t >= 20 and not window.dragging then
		if tab ~= lastTab then
			if currContainer then window.removeChild(currContainer) end
			currContainer = gui.container(0,1,window.w,window.h-1)
			cce = {}
			window.addChild(currContainer)
		end

		if tab == 1 then
			if tab ~= lastTab then
				cce.tabLabel = cce.tabLabel or gui.label(0,0,4,1,"tab1")
				currContainer.addChild(cce.tabLabel)
			end
			cce.tabLabel.text = tostring(math.random(111,999))
		elseif tab == 2 then
			if tab ~= lastTab then
				cce.cpuLabel = cce.cpuLabel or gui.label(1,1,4,1,"CPU: 0%")
				currContainer.addChild(cce.cpuLabel)
			end
			cce.cpuLabel.text = "CPU: "..roundToNearestOneDecimal(100-process.getAvgIdlePercentage()).."%"
		end
		lastTab = tab
		t = 0
	end
	t = t + 1
	os.sleep()
end