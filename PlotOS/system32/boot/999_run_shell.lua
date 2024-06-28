kern_log("Starting shell...")
package.on_booted()

_G.OSSTATUS = 1


--os.sleep(2)
require("screen").clear()



local e, process = xpcall(require, function(e)
    bsod(e, true)
end, "process")
if not e then
    while true do
        pcps()
    end
end

local fs = require("fs")

if not safemode then
    dofile("/PlotOS/cursor.lua")
    local s1, e1 = pcall(function()
        dofile("/PlotOS/systemAutorun.lua")
    end)

    if not s1 then
        kern_error("Error running system autorun: " .. e1)
    end
else
    kern_log("Safemode is enabled, skipping system autorun.", "warn")
end

if not safemode then
    local s2, e2 = pcall(function()
        dofile("/autorun.lua")
    end)

    if not s2 then
        kern_error("Error running autorun: " .. e2)
    end
else
    kern_log("Safemode is enabled, skipping autorun.", "warn")
end

xpcall(process.autoTick, function(e)
    bsod(e)
end)
