local ret = {}
local fs = package.require("fs")
local reg = package.require("registry")
local ipc = package.require("ipc")
local process = package.require("process")
local cp = component
ret.loaded = {}
local drivers = {}
local driver_cache = {}

function generate_unique_id()
    -- generate a unique id, 16 chars a-z0-9
    local id = ""
    for i = 1, 16 do
        local r = math.random(1, 36)
        if r <= 26 then
            id = id .. string.char(r + 96)
        else
            id = id .. string.char(r + 21)
        end
    end
    return id
end

function ret.getDriver(path)
    if not ret.loaded[path] then
        printk("Loading driver " .. path)
        local driverPath = "/driver/" .. path
        if fs.exists(driverPath) then
            ret.loaded[path] = raw_dofile(driverPath)
            local type = path:match("(.*)/(.*)")
            printk("Driver type: " .. type)
            ret.loaded[path].type = type
        else
            error('Driver doesn\'t exist')
        end
    end
    local d = ret.loaded[path]

    return d
end

function ret.getBest(type, addr)
    --[[if not type then
        -- check all types
        for k,v in fs.list("/driver") do
            for kk,vv in fs.list("/driver/"..k) do
                print(k..", "..kk)
                local d = ret.getDriver(k..""..kk)
                if d.compatible(addr) then
                    return d
                end
            end
        end
        return nil
    end
    for k,v in fs.list("/driver/"..type) do
        local d = ret.getDriver(type.."/"..k)
        if d.compatible(addr) then
            return d
        end
    end]]
    -- first check loaded drivers
    for k, v in pairs(ret.loaded) do
        if v and v.compatible(addr) and (not type or v.type == type) then
            return v
        end
    end
    -- then check all drivers
    if not type then
        -- check all types
        for k, v in fs.list("/driver") do
            for kk, vv in fs.list("/driver/" .. k) do
                print(k .. ", " .. kk)
                local d = ret.getDriver(k .. "" .. kk)
                if d.compatible(addr) then
                    return d
                end
            end
        end
        return nil
    end
    for k, v in fs.list("/driver/" .. type) do
        local d = ret.getDriver(type .. "/" .. k)
        if d.compatible(addr) then
            return d
        end
    end
    return nil
end

function ret.getDefault(type)
    local defa = nil
    if type == "drive" then
        return ret.getBest(type, computer.getBootAddress())
    end
    for k, v in pairs(cp.list()) do
        local d = ret.getBest(type, k)
        if d then
            return d, k
        end
    end

    return defa
end

-- we return the info (version, name, etc)
function ret.getinfo(type, addr)
    if not addr then addr = "default" end

    if addr == "default" then
        local d, addra = ret.getDefault(type)
        if d then
            return d.getName(), d.getVersion(), addra
        else
            return nil, "No driver found"
        end
    else
        local d = ret.getBest(type, addr)
        if d then
            return d.getName(), d.getVersion(), addr
        else
            return nil, "No driver found"
        end
    end
end

local segg = function(e)
    return e, debug.traceback("", 1)
end

function newdriver(d, addr)
    local ok, dd, tb = xpcall(d.new, function(e) return e, debug.traceback("", 1) end, addr)
    if not ok then
        bsod("Failed to load driver: " .. dd, false, tb)
    end
    dd.getDriverName = d.getName
    dd.getDriverVersion = d.getVersion
    -- wrap all methods in a xpcall so when called and errors, throws a bsod
    --[[if reg.get("system/security/driver_crash_bsod") == 1 then
        for k, v in pairs(dd) do
            if type(v) == "function" then
                dd[k] = function(...)
                    local re = { xpcall(v, segg, ...) }
                    if not re[1] then
                        bsod("Failed to call driver method: " .. re[2], false, re[3])
                    end
                    return table.unpack(re, 2)
                end
            end
        end
    end]]
    
    --local drv_ipc_id = "driver_"..generate_unique_id()

    --[[for k,v in pairs(dd) do
        if type(v) == "function" then
            dd[k] = function(...)
                if process.currentProcess then
                    local re = { ipc.call(drv_ipc_id, ...)}
                    printk("Driver method "..k.." returned "..tostring(re[1]))
                    return table.unpack(re)
                else
                    printk("Driver method "..k.." called")
                    return v(...)        
                end
            end
        end
    end

    ipc.register(drv_ipc_id, function(method, ...)
    printk("Driver method "..method.." called")
        if not dd[method] then
            return false, "Method not found"
        end
        local ok, ret = xpcall(dd[method], function(e) return e, debug.traceback("", 1) end, ...)
        if not ok then
            bsod("Failed to call driver method: " .. ret, false, debug.traceback("", 1))
        end
        return true, ret
    end)]]

    --[[ipc.register("driver", function(driver, addr, method, ...)
        local drv = ret.load(driver, addr)
        if not drv then
            return false, "No driver found"
        end
        if not drv[method] then
            return false, "Method not found"
        end
        local ok, ret = xpcall(drv[method], function(e) return e, debug.traceback("", 1) end, ...)
        if not ok then
            bsod("Failed to call driver method: " .. ret, false, debug.traceback("", 1))
        end
        return true, ret

    end)]]

    local _ret = dd
    --[[
    if process.currentProcess then
        _ret = {}
        setmetatable(_ret, {
            __index = function(t, k)
                if type(dd[k]) == "function" then
                    return function(...)
                        return coroutine.yield("driver", addr, k, ...)
                    end
                else
                    return dd[k]
                end
            end
        })
    end
    ]]

    return dd
end

function ret.load(typed, addr)
    if not addr then addr = "default" end

    if addr == "default" then
        
        local d, addra = ret.getDefault(typed)
        if d then
            local dd = newdriver(d, addra)
            dd.getDriverName = d.getName
            dd.getDriverVersion = d.getDriverVersion
            dd.address = addra
            driver_cache[addra] = dd

            local dd_proxy = {}
            if process.currentProcess ~= nil then
                setmetatable(dd_proxy, {
                    __index = function(t, k)
                        if type(dd[k]) == "function" then
                            return function(...)
                                return coroutine.yield("driver", addra, k, ...)
                            end
                        else
                            return dd[k]
                        end
                    end
                })
            else
                printk("A driver has been loaded outside of a process (kernel or we have a major security issue)")
                dd_proxy = dd
            end

            --dd_proxy = dd

            return dd_proxy
        else
            return nil, "No drivers found"
        end
    else
        if driver_cache[addr] then
            return driver_cache[addr]
        end
        local d = ret.getBest(type, addr)
        if d then
            local dd = newdriver(d, addr)
            dd.getDriverName = d.getName
            dd.getDriverVersion = d.getVersion
            dd.address = addr
            driver_cache[addr] = dd
            
            local dd_proxy = {}

            if process.currentProcess ~= nil then
                setmetatable(dd_proxy, {
                    __index = function(t, k)
                        if type(dd[k]) == "function" then
                            return function(...)
                                return coroutine.yield("driver", addr, k, ...)
                            end
                        else
                            return dd[k]
                        end
                    end
                })
            else
                printk("A driver has been loaded outside of a process (kernel or we have a major security issue)")
                dd_proxy = dd
            end

            --dd_proxy = dd

            return dd_proxy
        else
            return nil, "No drivers found"
        end
    end
end

function ret.fromCache(addr)
    return driver_cache[addr]
end



return ret
