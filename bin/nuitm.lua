local gui = require("newgui")
local gpu = require("driver").load("gpu")

local w,h = gpu.getResolution()
local tab = 1
local t = 1

--local panel = gui.panel(1,1,w,h)
--panel.color = 0xbbbbbb
--workspace.addChild(panel)
local window = gui.window(10,10,75,35)
window.content.color = 0xcccccc

local procButton = gui.button(0,0,25,1,"Processes")
procButton.color = 0xbbbbbb
procButton.eventbus.on("click", function()
	tab = 1
	t = 20
	print(tab)
end)

local perfButton = gui.button(27,0,25,1,"Performance")
perfButton.color = 0xbbbbbb
perfButton.eventbus.on("click", function()
	tab = 2
	t = 20
	print(tab)
end)

window.addChild(procButton)
window.addChild(perfButton)
gui.workspace.addChild(window)

while not window.isClosed do
	if t >= 20 then
		if tab == 1 then

		elseif tab == 2 then

		end
	end
	t = t + 1
end