local raw_loadfile = ...

local bootScripts

do
    local res, err = raw_loadfile("/PlotOS/bootInit.lua")
    if not res then error(err) end
    bootScripts = res(...)
end

local function boot(scripts)
    do
        for i = 1, #scripts do
            printk("Running boot script " .. scripts[i])
            raw_dofile(scripts[i])
        end
    end
end

do
    local ok, e = xpcall(boot, function(e)
        return tostring(e) .. "\n" .. tostring(debug.traceback("", 2))
    end, bootScripts)

    if not ok then
        kern_panic("Critical system failure: " .. tostring(e))
    end
end

computer.beep(1000)
kern_panic("System halted!")
