
local gui = require("newgui")
local gpu = require("driver").load("gpu")



local w,h = gpu.getResolution()


for i=1,1 do
	local win = gui.window(math.random(1,w-55),math.random(1,h-10),45,10)
	win.title = "Window "..i
	for i=1,10 do
		win.addChild(gui.label(1,i,45, 1, tostring(math.random())))
	end
	gui.workspace.addChild(win)
end

