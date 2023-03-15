
local gui = require("gui")
local gpu = require("driver").load("gpu")
local buffering = require("doublebuffering")



local w,h = gpu.getResolution()

local buf = buffering.getMain()
local workspace = gui.workspace



local win = gui.window(10,10,45,30,"")

win.titlebar.children[1].color = 0x1d4fb8
win.container.children[1].color = 0x1d4fb8

win:addChild(gui.text(5,2,"PlotOS has protected your PC", 0xffffff, 0x1d4fb8))
win:addChild(gui.text(5,4,"PlotOS Defender SmartScreen", 0xffffff, 0x1d4fb8))
win:addChild(gui.text(5,5,"has prevented an unrecognized", 0xffffff, 0x1d4fb8))
win:addChild(gui.text(5,6,"app from starting. Running this app", 0xffffff, 0x1d4fb8))
win:addChild(gui.text(5,7,"might put your PC at risk.", 0xffffff, 0x1d4fb8))

local btn = gui.button(45-13,30-5, 12,3,"Don't run")

btn.action = function()
    win:close()
end

win:addChild(btn)

workspace:addChild(win)

workspace._tick()
workspace._draw(buf)

buf.draw()

