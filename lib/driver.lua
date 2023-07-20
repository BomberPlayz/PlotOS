local ret = {}
local fs = package.require("fs")
local cp = component
ret.loaded = {}
function ret.getDriver(path)
    if not ret.loaded[path] then
        kern_info("Loading driver "..path)
        local driverPath = "/driver/"..path
        if fs.exists(driverPath) then
            ret.loaded[path] = raw_dofile(driverPath)
            local type = path:match("(.*)/(.*)")
            kern_info("Driver type: "..type)
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
    for k,v in pairs(ret.loaded) do
        kern_info("Checking driver "..k)
        if v and v.compatible(addr) and (not type or v.type == type) then
            kern_info("Driver "..k.." is compatible (type: "..v.type..")")
            return v
        end
    end
    -- then check all drivers
    if not type then
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
    end
    return nil
end

function ret.getDefault(type)
    local defa = nil
    if type == "drive" then
        kern_info("Getting default drive")
        return ret.getBest(type, computer.getBootAddress())
    end
    for k,v in pairs(cp.list()) do
        local d = ret.getBest(type, k)
        if d then
            return d,k
        end
    end

    return defa
end

-- we return the info (version, name, etc)
function ret.getinfo(type, addr)
    if not addr then addr = "default" end

    if addr == "default" then
        local d,addra = ret.getDefault(type)
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
        bsod("Failed to load driver: "..dd, false, tb)
    end
    dd.getDriverName = d.getName
    dd.getDriverVersion = d.getVersion
    -- wrap all methods in a xpcall so when called and errors, throws a bsod
    for k,v in pairs(dd) do
        if type(v) == "function" then
            dd[k] = function(...)
                local re = { xpcall(v, segg, ...) }
                if not re[1] then
                    bsod("Failed to call driver method: "..re[2], false, re[3])
                end
                return table.unpack(re, 2)
            end
        end
    end



    return dd
end

function ret.load(type, addr)
    if not addr then addr = "default" end

    if addr == "default" then
        local d,addra = ret.getDefault(type)
        if d then
            local dd = newdriver(d, addra)
            dd.getDriverName = d.getName
            dd.getDriverVersion = d.getDriverVersion
            dd.address = addra
            return newdriver(d, addra)
        else
            return nil, "No drivers found"
        end
    else
        local d = ret.getBest(type, addr)
        if d then
            local dd = newdriver(d, addr)
            dd.getDriverName = d.getName
            dd.getDriverVersion = d.getVersion
            dd.address = addr
            return dd
        else
            return nil, "No drivers found"
        end
    end

end

return ret
