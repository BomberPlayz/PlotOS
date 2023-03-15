
local gui = require("gui")
local gpu = require("driver").load("gpu")
local buffering = require("doublebuffering")



local w,h = gpu.getResolution()

local buf = buffering.getMain()
local workspace = gui.workspace





for i=1,1 do
    workspace:addChild(gui.window(math.random(1,w-55),math.random(1,h-10),45,10,"Test"..i))
end
workspace._tick()
workspace._draw(buf)

buf.draw()

