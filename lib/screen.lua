local api = {}

local gpu = require("driver").load("gpu")

api.clear = function()
  local w,h = gpu.getResolution()
  gpu.fill(1,1,w,h," ")
end

api.setRes = function(res) gpu.setResolution(res) end

return api