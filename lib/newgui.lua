local buffering = require("doublebuffering")
local gpu = require("driver").load("gpu")
local event = require("event")
local reg = require("registry")

local gui = {}
gui.event = event.emitter()

function gui.component(x,y,w,h)
    local t = {}
    t.x = x
    t.y = y
    t.w = w
    t.h = h

end