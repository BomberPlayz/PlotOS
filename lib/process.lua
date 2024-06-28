-- TODO rewrite
-- TODO rewrite
-- TODO rewrite
local api = {}
api.processes = {}
api.signal = {}
api.currentProcess = nil

function api.getCurrentProcess()
    return api.currentProcess
end

local unusedTime = 0
local security = require("security")
local gpu = require("driver").load("gpu")
local reg = require("registry")
local stream = require("stream")
local as_pid = 1
local usedTime = 0
local function setfenv(f, env)
    local _ENV = env or {}     -- create the _ENV upvalue
    return function(...)
        print('upvalue', _ENV) -- address of _ENV upvalue
        return f(...)
    end
end
local _signal = nil

-- Finds a process by its associated thread.
-- @param thread The thread to search for.
-- @param process (optional) The process or list of processes to search within. If not provided, the global list of processes will be used.
-- @return The process that matches the given thread, or nil if no match is found.
api.findByThread = function(thread, process)
    -- process is optional
    process = process or api.processes

    for _, subProcess in ipairs(process) do
        if subProcess.thread == thread then
            return subProcess
        elseif #subProcess.processes > 0 then
            local t = api.findByThread(thread, subProcess.processes)
            if t then
                return t
            end
        end
    end
end

--- Checks if the current Lua function is running as a process.
--- @return boolean True if the function is running as a process, false otherwise.
api.isProcess = function()
    if api.currentProcess then
        return true
    end
end


--- Creates a new process with the specified parameters.
--- @param name (string) - The name of the process.
--- @param code (string) - The code to be executed by the process.
--- @param env? (table) [optional] - The environment table for the process.
--- @param perms? (table) [optional] - The permissions table for the process.
--- @param inService? (boolean) [optional] - Indicates whether the process is in service.
--- @param ...? - Additional arguments to be passed to the process.
--- @return (table) # The newly created process object.
api.new = function(name, code, env, perms, inService, ...)
    local ret = {}
    ret.listeners = {}
    ret.on = function(event, callback)
        table.insert(ret.listeners, {
            event = event,
            callback = callback
        })
    end
    ret.off = function(event, callback)
        for k, v in pairs(ret.listeners) do
            if v.event == event and v.callback == callback then
                table.remove(ret.listeners, k)
            end
        end
    end
    ret.emit = function(event, ...)
        for k, v in pairs(ret.listeners) do
            if v.event == event then
                v.callback(...)
            end
        end
    end


    --env._G = env
    --print(code)

    --[[local env = env or {}
	env.__process__ = ret
	env._G = env
	setmetatable(env, { __index = _G })]]

    local code = load(code, "=" .. name, nil, _G)
    -- debug fuckery for forcing pre-emptive multitasking
    ret.thread = coroutine.create(code)
    ret.name = name or "not defined"
    ret.status = "running"
    ret.err = ""
    ret.args = table.pack(...)



    ret.io = {}
    ret.io.signal = {}
    ret.io.signal.pull = {}
    ret.io.signal.queue = {}
    ret.pid = as_pid
    ret.lastCpuTime = 0
    ret.cputime_avg = {}
    ret.processes = {}
    ret.io.screen = {

    }
    ret.io.screen.width, ret.io.screen.height = gpu.getResolution()
    ret.io.screen.offset = { x = 0, y = 0 }
    ret.io.stdin = stream.new()
    ret.io.stdout = stream.new()
    as_pid = as_pid + 1

    function ret:getCpuTime()
        return ret.lastCpuTime
    end

    function ret:getCpuPercentage()
        local allcputime = 0
        for k, v in ipairs(api.list()) do
            allcputime = allcputime + v:getCpuTime()
        end
        return ret.lastCpuTime > 0 and (math.min(((ret.lastCpuTime*1000)/50), 1)) or 0
    end

    function ret:getAvgCpuTime()
        local rama = 0
        for k, v in ipairs(ret.cputime_avg) do
            rama = rama + v
        end
        rama = rama / #ret.cputime_avg
        return rama
    end

    function ret:getAvgCpuPercentage()
        local allcputime = 0
        for k, v in ipairs(api.list()) do
            allcputime = allcputime + v:getAvgCpuTime()
        end
        allcputime = allcputime + api.getAvgIdleTime()
        --return ret:getAvgCpuTime() > 0 and (ret:getAvgCpuTime() / allcputime * 100) or 0
        --kern_log(ret:getAvgCpuTime())
        return allcputime > 0 and (math.min((ret:getAvgCpuTime()*1000)/50, 1)) or 0
    end

    function ret:kill()
        self.status = "dying"
    end

    function ret:terminate()
        self.status = "dead"
    end

    function ret:getStatus()
        return self.status
    end

    if reg.get("system/processes/attach_security") == 1 then
        security.attach(ret)
    end

    if api.isProcess() and not forceRoot then
        local p = api.currentProcess
        table.insert(p.processes, ret)
        ret.parent = p
    else
        table.insert(api.processes, ret)
    end

    kern_log("New process named " .. ret.name .. " with pid" .. ret.pid .. " created")

    return ret
end

--- Loads a file from the specified path and returns a new API object.
--- @param name (string) - The name of the API object.
--- @param path (string) - The path to the file to be loaded.
--- @param perms (table) - Optional permissions for the API object.
--- @param forceRoot (boolean) - Whether to force the API object to be rooted.
--- @param ... - Additional arguments to be passed to the API constructor.
--- @return (table, string) - The loaded API object or nil if loading failed, and an error message if applicable.
api.load = function(name, path, perms, forceRoot, ...)
    local fs = require("fs")
    if path:sub(1, 1) ~= "/" then
        path = (os.currentDirectory or "/") .. "/" .. path
    end
    local handle, open_reason = fs.open(path)
    if not handle then
        return nil, open_reason
    end
    local buffer = {}
    while true do
        local data, reason = handle:read(1024)
        if not data then
            handle:close()
            if reason then
                return nil, reason
            end
            break
        end
        buffer[#buffer + 1] = data
    end
    return api.new(name, table.concat(buffer), nil, perms, forceRoot, ...)
end

local toRemoveFromProc = {}

local driverCache = {}

-- print(coroutine.status(v.thread))
api.tickProcess = function(v)
    if v.status == "running" or v.status == "idle" then
        if coroutine.status(v.thread) == "suspended" then
            if #v.io.signal.pull > 0 then
                if not v.io.signal.queue[1] then
                    local a, b, c, d, e, f, g, aa, ss = computer.pullSignal(0)
                    if a then
                        table.insert(v.io.signal.queue, { a, b, c, d, e, f, g, aa, ss })
                    end
                end
                local puk = v.io.signal.pull[#v.io.signal.pull]
                if type(v.io.signal.queue[1]) == "table" and v.io.signal.queue[1][1] or (computer.uptime() >= puk.timeout + puk.start_at) then
                    v.status = "running"
                    v.io.signal.pull[#v.io.signal.pull].ret = v.io.signal.queue[1] or {}
                    if v.io.signal.queue[1] then
                        table.remove(v.io.signal.queue, 1)
                    end
                    local st = computer.uptime() * 1000
                    api.currentProcess = v
                    local reta = { coroutine.resume(v.thread, table.unpack(v.args)) }
                    api.currentProcess = nil
                    if not reta[1] then
                        v.err = reta[2] or "Died"
                    else
                        table.remove(reta, 1)
                        if reta[1] ~= nil then
                            local syscall = table.remove(reta, 1)
                            local args = reta
                            if syscall == "driver" then
                                if not driverCache[args[1]] then
                                    local drv = require("driver").load(args[1])
                                    driverCache[args[1]] = drv
                                end
                                if driverCache[args[1]] then
                                    local fn = driverCache[args[1]][args[2]]
                                    table.remove(args, 1)
                                    table.remove(args, 1)
                                    local ret = fn(table.unpack(args))
                                    v.sysret = ret
                                end
                            end
                        end
                    end
                    local et = computer.uptime() * 1000
                    v.lastCpuTime = et / 1000 - st / 1000
                    for kk, vv in ipairs(v.processes) do
                        v.lastCpuTime = v.lastCpuTime + vv.lastCpuTime
                    end
                    usedTime = usedTime + v.lastCpuTime
                    table.insert(v.cputime_avg, v.lastCpuTime)
                    if #v.cputime_avg > 24 then
                        table.remove(v.cputime_avg, 1)
                    end
                    return ret
                else
                    v.status = "idle"
                    v.lastCpuTime = 0
                    for kk, vv in ipairs(v.processes) do
                        v.lastCpuTime = v.lastCpuTime + vv.lastCpuTime
                    end
                    usedTime = usedTime + v.lastCpuTime
                    table.insert(v.cputime_avg, v.lastCpuTime)
                    if #v.cputime_avg > 24 then
                        table.remove(v.cputime_avg, 1)
                    end
                end
            else
                local a, b, c, d, e, f, g, aa, ss = computer.pullSignal(0)
                if a then
                    table.insert(v.io.signal.queue, { a, b, c, d, e, f, g, aa, ss })
                end
                local st = computer.uptime() * 1000
                api.currentProcess = v
                local reta = { coroutine.resume(v.thread, table.unpack(v.sysret or v.args)) }
                api.currentProcess = nil
                if not reta[1] then
                    v.err = reta[2] or "Died"
                end
                table.remove(reta, 1)
                if reta[1] ~= nil then
                    local syscall = table.remove(reta, 1)
                    local args = reta
                    if syscall == "driver" then
                        if not driverCache[args[1]] then
                            local drv = require("driver").load(args[1])
                            driverCache[args[1]] = drv
                        end
                        if driverCache[args[1]] then
                            local fn = driverCache[args[1]][args[2]]
                            table.remove(args, 1)
                            table.remove(args, 1)
                            local ret = fn(table.unpack(args))
                            v.sysret = ret
                        end
                    end
                end
                local et = computer.uptime() * 1000
                v.lastCpuTime = et / 1000 - st / 1000
                for kk, vv in ipairs(v.processes) do
                    v.lastCpuTime = v.lastCpuTime + vv.lastCpuTime
                end
                usedTime = usedTime + v.lastCpuTime
                table.insert(v.cputime_avg, v.lastCpuTime)
                if #v.cputime_avg > 32 then
                    table.remove(v.cputime_avg, 1)
                end
                return ret
            end
        elseif coroutine.status(v.thread) == "dead" then
            v.status = "dying"
        end
    elseif v.status == "dead" then
        table.insert(toRemoveFromProc, v)
    elseif v.status == "dying" then
        v.emit("exit")
        kern_log("Process with name " .. v.name .. " with pid " .. v.pid .. " has died: " .. v.err)
        v.io.signal.pull = {}
        v.io.signal.queue = {}
        v.err = ""
        v.lastCpuTime = 0
        v.status = "dead"
    end
    api.currentProcess = nil
end
local idleTimeAvg = {}

api.tick = function()
    local ae = 0
    local s = computer.uptime()
    usedTime = 0

    local function ticker(processes)
        for k, v in ipairs(processes) do
            ae = ae + 1
            if #v.processes > 0 then
                --print(#v.processes)
                ticker(v.processes)
            end
            local a, e = api.tickProcess(v)
            if v.lastCpuTime * 1000 > 65 then
                --kern_info("Detected process "..v.pid.." ("..v.name..") slowing down system: "..(v.lastCpuTime*1000).." ms CPU time", "warn")
            end
            --ticker(v.processes)
            -- print(v.name)
        end
    end
    ticker(api.processes)

    for k, v in ipairs(toRemoveFromProc) do
        if not v.parent then
            for i = 1, #api.processes do
                if api.processes[i].pid == v.pid then
                    table.remove(api.processes, i)
                    break
                end
            end
        else
            for i = 1, #v.parent.processes do
                if v.parent.processes[i].pid == v.pid then
                    table.remove(v.parent.processes, i)
                    break
                end
            end
        end
    end
    local e = computer.uptime()
    usedTime = 0

    for k, v in ipairs(api.processes) do
        usedTime = usedTime + v.lastCpuTime
    end

    unusedTime = e - s
    unusedTime = unusedTime - usedTime
    table.insert(idleTimeAvg, unusedTime)
    if #idleTimeAvg > 32 then
        table.remove(idleTimeAvg, 1)
    end
    --print(tostring(ae))
end

api.getIdleTime = function()
    return unusedTime
end

api.getIdlePercentage = function()
    local allUsed = 0
    for k, v in ipairs(api.processes) do
        allUsed = allUsed + v.getCpuTime()
    end
    allUsed = allUsed + api.getIdleTime()
    return allUsed > 0 and (api.getIdleTime() / allUsed * 100) or 100
end

api.getAvgIdleTime = function()
    local rata = 0
    for k, v in ipairs(idleTimeAvg) do
        rata = rata + v
    end
    rata = rata / #idleTimeAvg
    return rata
end

api.getAvgIdlePercentage = function()
    local allUsed = 0
    for k, v in ipairs(api.processes) do
        allUsed = allUsed + v.getAvgCpuTime()
    end
    allUsed = allUsed + api.getAvgIdleTime()
    return allUsed > 0 and (api.getAvgIdleTime() / allUsed * 100) or 100
end

api.autoTick = function()
    local lastTick = 0
    while true do
        lastTick = lastTick + 1

        api.tick()

        if lastTick > 100 then
            os.sleep(0)
            lastTick = 0
        end
        computer._signal = nil
    end
end

api.list = function(filter)
    local ret = {}
    for k, v in ipairs(api.processes) do
        if string.match(v.name, filter or "") then
            table.insert(ret, v)
        end
    end
    return ret
end

api.setStatus = function(pid, status)
    for k, v in ipairs(api.processes) do
        if v.pid == pid then
            v.status = status
        end
    end
    return false
end

api.suspend = function(pid)
    api.setStatus(pid, "suspended")
end

api.resume = function(pid)
    api.setStatus(pid, "running")
end

return api
