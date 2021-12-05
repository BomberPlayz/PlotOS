local api = {}

api.clear = function()
  local w,h = component.gpu.getResolution()
  component.gpu.fill(1,1,w,h," ")
end

api.setRes = function(res) component.gpu.setResolution(res) end

return api