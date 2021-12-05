local gui = require("gui")
local gpu = require("driver").load("gpu")
local buffering = require("doublebuffering")



local w,h = gpu.getResolution()

local buf = buffering.getMain()
local workspace = gui.container(1,1,w,h)




workspace:addChild(gui.window(10,10,75,10,"Test"))

workspace._tick()
workspace._draw(buf)

buf.draw()

