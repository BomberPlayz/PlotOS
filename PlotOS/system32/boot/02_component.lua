local cp = component.proxy

local security = require("security")
local process = require("process")
component.proxy = function(addr)
  if process.isProcess() then
    local proc = process.findByThread(coroutine.running())
    if proc.security.hasPermission("component.access_all") then
      return cp(addr)
    else
      return nil, "EPERM", "Permission denied for accessing component"
    end
  else
    return cp(addr)
  end
end

setmetatable(component, {
  __index = function(_,k)
    return component.proxy(component.list(k)())
  end
})