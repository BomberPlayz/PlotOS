
local gui = require("gui")
local gpu = require("driver").load("gpu")
local buffering = require("doublebuffering")



local w,h = gpu.getResolution()

local buf = buffering.getMain()
local workspace = gui.workspace

local win = gui.window(20,20,100,30,"Device Manager")
workspace:addChild(win)
local yy = 2
local function addDevice(name,driver)
    local lbl = gui.text(2,yy,name)
    local lbl2 = gui.text(40,yy,driver)
    yy = yy + 1
    win:addChild(lbl)
    win:addChild(lbl2)
end

for k,v in component.list() do
    print(v)
    local drv = require("driver").load(nil, k)
    addDevice(k,drv and drv.getDriverName() or "Unknown")
end



workspace._tick()
workspace._draw(buf)

buf.draw()

