local reg = package.require("registry")
local process = package.require("process")

local lib = {}
lib.running = {}

function lib.registerService(name, path, args, dependencies, pathiscode)
    reg.set("system/services/" .. name .. "/name", name, reg.types.string)
    reg.set("system/services/" .. name .. "/path", path, reg.types.string)
    for k, v in pairs(args) do
        reg.set("system/services/" .. name .. "/args/" .. k, tostring(v), reg.types.string)
    end
    for k, v in pairs(dependencies) do
        reg.set("system/services/" .. name .. "/dependencies/" .. k, v, reg.types.string)
    end
    reg.set("system/services/" .. name .. "/pathiscode", pathiscode, reg.types.boolean)
end

function lib.start(svc)
    if not svc then
        error("missing argument 1: svc")
    end

    local svc = reg.get("system/services/" .. svc)
    if svc then
        -- is it already running?
        if lib.running[svc.name] then
            return lib.running[svc.name]
        end

        local dependencies = svc.dependencies




        if dependencies then
            local pdeps = {}
            for k, v in pairs(dependencies) do
                pdeps[tonumber(k)] = v
            end
            for k, v in ipairs(pdeps) do
                if not lib.running[v] then
                    lib.start(v)
                end
            end
        end
        local pathiscode = svc.pathiscode
        if not pathiscode then
            local path = svc.path
            local args = svc.args

            --system/services/potato/args/1, 2, etc
            local pargs = {}
            for k, v in pairs(args) do
                pargs[tonumber(k)] = v
            end

            local proc = process.load(path, nil, nil, nil, table.unpack(pargs))
            lib.running[svc.name] = proc
            return proc
        else

        end
    else
        return nil, "Service nonexistent"
    end
end

function svc.stop(svc)

end

return lib
