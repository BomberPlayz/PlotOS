
local gui = require("newgui")
local gpu = require("driver").load("gpu")
local buffering = require("doublebuffering")



local w,h = gpu.getResolution()

local workspace = gui.workspace

local win = gui.window(20,20,100,30,"Device Manager")
workspace.addChild(win)
local yy = 2
local function addDevice(name,driver)
    local lbl = gui.label(2,yy,40, 20, name)
    local lbl2 = gui.label(40,yy,60, 20, driver)
    yy = yy + 1
    win.addChild(lbl)
    win.addChild(lbl2)
end

for k,v in component.list() do
    print(v)
    local drv = require("driver").load(nil, k)
    addDevice(k,drv and drv.getDriverName() or "Unknown")
end


