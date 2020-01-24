local inet = require("internet")
local shell = require("shell")
local response = inet.request("https://raw.githubusercontent.com/BomberPlayz/PlotOS/master/ver")
local body = ""
for chunk in response do
  body = body .. chunk
end

local file = io.open("/ver")
local line = file:read(1)..file:read(2)..file:read(3)..file:read(4)..file:read(5)
  if body == line then
    return
  else
    shell.execute("/home/posinst")
  end
