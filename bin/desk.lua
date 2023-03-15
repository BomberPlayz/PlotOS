local gui = require("gui")
local gpu = require("driver").load("gpu")
local buffering = require("doublebuffering")



local w,h = gpu.getResolution()

local buf = buffering.getMain()
local workspace = gui.workspace

local taskbar = gui.container(1, h, w, 1)
taskbar:addChild(gui.panel(0,0,w,1,0xaaaaaa))

local startButton = gui.button(0, 0, 5, 1, "Start")
taskbar:addChild(startButton)

workspace:addChild(taskbar)