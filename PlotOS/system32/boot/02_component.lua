local oldcom = component

_G.component = {}

local security = require("security")
local process = require("process")
component.proxy = function(addr)
    if process.isProcess() then
        local proc = process.findByThread(coroutine.running())
        if proc.security and proc.security.hasPermission("component.access.*") or proc.security and proc.security.hasPermission("component.access." .. oldcom.proxy(addr).type) then
            return oldcom.proxy(addr)
        elseif proc.security then
            printk("Permission denied to access component by proxy for " .. proc.pid .. " (" .. proc.name .. ")",
                "warn")
            return nil, "EPERM", "Permission denied for accessing component"
        else
            return oldcom.proxy(addr)
        end
    else
        return oldcom.proxy(addr)
    end
end

component.invoke = function(addr, ...)
    if process.isProcess() then
        local proc = process.findByThread(coroutine.running())
        if proc.security and proc.security.hasPermission("component.access.*") or proc.security and proc.security.hasPermission("component.access." .. oldcom.proxy(addr).type) then
            return oldcom.invoke(addr, ...)
        elseif proc.security then
            printk("Permission denied to access component by invoke for " .. proc.pid .. " (" .. proc.name .. ")",
                "warn")
            return nil, "EPERM", "Permission denied for accessing component"
        else
            return oldcom.invoke(addr, ...)
        end
    else
        return oldcom.invoke(addr, ...)
    end
end

setmetatable(component, {
    __index = function(_, k)
        if (oldcom[k]) then
            return oldcom[k]
        end
        return component.proxy(oldcom.list(k)())
    end
})
