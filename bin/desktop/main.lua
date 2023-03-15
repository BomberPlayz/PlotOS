local gui = require("gui")
local gpu = require("driver").load("gpu")
local buffering = require("doublebuffering")



local w,h = gpu.getResolution()

local buf = buffering.getMain()
local workspace = gui.workspace

local taskbar = gui.container(0, h, w, 1)
taskbar.backgroundColor = 0xaaaaaa

local startButton = gui.button(0, 0, 5, 1, "Start")
taskbar:addChild(startButton)

workspace:addChild(taskbar)