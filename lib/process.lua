local api = {}
api.processes = {}
api.signal = {}
api.currentProcess = nil

function api.getCurrentProcess()
    return api.currentProcess
end

local unusedTime = 0
local security = package.require("security")

local reg = package.require("registry")
local stream = package.require("stream")
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

-- Define syscall types
local SYSCALLS = {
    DRIVER = 1,
    FS = 2,
    PROCESS = 3,
    -- etc
}

--- Finds a process by its associated thread.
--- @param thread thread The thread to search for.
--- @param process? process The process or list of processes to search within. If not provided, the global list of processes will be used.
--- @return number? pid The process that matches the given thread, or nil if no match is found.
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
--- @return boolean? True if the function is running as a process, false otherwise.
api.isProcess = function()
    if api.currentProcess then
        return true
    end
end

--- @class process
--- @field pid number The unique process ID
--- @field name string The name of the process
--- @field thread thread The actual Lua thread object
--- @field err string Any error message associated with the process
--- @field args table The arguments passed to the process
--- @field processes table List of child processes
--- @field parent process? The parent process (nil if root process)
--- @field lastCpuTime number The CPU time used in the last tick
--- @field cputime_avg table[] Array of recent CPU time measurements
--- @field listeners table[] Array of event listeners
--- @field io table Input/output handlers and buffers
--- @field status string Current process status ("running", "idle", "dying", "dead")

--- Creates a new process with the specified parameters.
--- @param name (string) - The name of the process.
--- @param code (string) - The code to be executed by the process.
--- @param env? (table) - The environment table for the process.
--- @param perms? (table) - The permissions table for the process.
--- @param inService? (boolean)- Indicates whether the process is in service.
--- @param ...? any Additional arguments to be passed to the process.
--- @return (process) # The newly created process object.
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

    --local code = load(code, "=" .. name, nil, _G)

    local _code = ""
    local i = 1
    local in_string = false
    local string_char = nil
    local in_comment = false
    local in_multiline_string = false

    while i <= #code do
        local c = code:sub(i,i)

        -- Handle multiline string detection
        if not in_string and not in_multiline_string and c == "[" and code:sub(i+1,i+1) == "[" then
            in_multiline_string = true
            _code = _code .. "[["
            i = i + 2
            goto continue
        elseif in_multiline_string and c == "]" and code:sub(i+1,i+1) == "]" then
            in_multiline_string = false
            _code = _code .. "]]" -- remember to put \]\] back
            i = i + 2
            goto continue
        end

        -- Handle regular string detection
        if not in_multiline_string and not in_string and (c == '"' or c == "'") then
            in_string = true
            string_char = c
        elseif in_string and c == string_char and code:sub(i-1,i-1) ~= "\\" then
            in_string = false
        end

        -- Handle comment detection
        if not in_string and not in_multiline_string and c == "-" and code:sub(i+1,i+1) == "-" then
            in_comment = true
        elseif in_comment and c == "\n" then
            in_comment = false
        end

        -- Replace 'do' with 'do coroutine.yield()' only in actual code
        if not in_string and not in_multiline_string and not in_comment and 
            code:sub(i,i+1) == "do" and 
            (i == 1 or not code:sub(i-1,i-1):match("[%w_]")) and
            (i+2 > #code or not code:sub(i+2,i+2):match("[%w_]")) then
            _code = _code .. "do coroutine.yield();"
            i = i + 2
        else
            _code = _code .. c
            i = i + 1
        end

        ::continue::
    end

    --printk(_code)

    local code, err = load(_code, "=" .. name, nil, _G)
    if not code then
        printk("Failed to load process code: " .. err, "error")
        return
    end

    ret.thread = coroutine.create(code)
    ret.name = name or "not defined"
    ret.status = "running"
    ret.err = ""
    ret.args = table.pack(...)

    ret.io = {}
    ret.io.signal = {}
    ret.io.signal.pull = {}
    ret.io.signal.queue = {}
    ret.io.handles = {}
    ret.pid = as_pid
    ret.lastCpuTime = 0
    ret.cputime_avg = {}
    ret.processes = {}
    ret.io.screen = {}

    printk("load gpu drv")
    local gpu = package.require("driver").load("gpu")
    printk("loaded gpu drv")
    ret.io.screen.width, ret.io.screen.height = gpu.getResolution()
    printk("got resolution")
    ret.io.screen.offset = { x = 0, y = 0 }
    ret.io.stdin = stream.new()
    ret.io.stdout = stream.new()

    ret.ipc_waiting = false
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
        --printk(ret:getAvgCpuTime())
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

    if api.isProcess() then
        local p = api.currentProcess
        table.insert(p.processes, ret)
        ret.parent = p
    else
        table.insert(api.processes, ret)
    end

    printk("New process named " .. ret.name .. " with pid" .. ret.pid .. " created")

    return ret
end

--- Loads a file from the specified path and returns a new API object.
--- @param name (string) - The name of the API object.
--- @param path (string) - The path to the file to be loaded.
--- @param perms (table) - Optional permissions for the API object.
--- @param forceRoot (boolean) - Whether to force the API object to be rooted.
--- @param ... any Additional arguments to be passed to the API constructor.
--- @return table?, (string|table|boolean)? - The loaded API object or nil if loading failed, and an error message if applicable.
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
api.tickProcess = function(process, event) -- TODO: make more efficient?
    if process.status == "running" or process.status == "idle" then
        if coroutine.status(process.thread) == "suspended" then
            -- Handle signal queue
            if event[1] then
                table.insert(process.io.signal.queue, event)
            end

            -- Check if we should resume based on signals or timeout
            local shouldResume = false
            if #process.io.signal.pull > 0 then
                local pullSignal = process.io.signal.pull[#process.io.signal.pull]
                if type(process.io.signal.queue[1]) == "table" and process.io.signal.queue[1][1] or ((computer.uptime() >= (pullSignal.timeout) + pullSignal.start_at)) then
                    shouldResume = true
                    process.io.signal.pull[#process.io.signal.pull].ret = process.io.signal.queue[1] or {}
                    if process.io.signal.queue[1] then
                        table.remove(process.io.signal.queue, 1)
                    end
                end
            else
                shouldResume = true
            end

            if shouldResume then
                -- Resume the process
                local startTime = computer.uptime() * 1000
                api.currentProcess = process
                local resumeResult = { coroutine.resume(process.thread, table.unpack(process.sysret or process.args)) }
                
                process.sysret = nil
                api.currentProcess = nil

                if not resumeResult[1] then
                    process.err = resumeResult[2] or "Died"
                else
                    -- Handle syscalls if any
                    if resumeResult[2] then
                        table.remove(resumeResult, 1)
                        local syscall = table.remove(resumeResult, 1)
                        local args = resumeResult

                        if syscall == "ipc_call" then
                            local handler_name = args[1]
                            local handler_args = args[2]
                            local handler = require("ipc").handlers[handler_name]

                            if not handler then
                                process.sysret = table.pack(false, "Handler not found")
                            else
                                if handler.process then
                                    table.insert(handler.process.io.signal.queue, {
                                        "ipc_request",
                                        handler_name,
                                        process,
                                        table.unpack(handler_args)
                                    })
                                    process.status = "suspended"
                                    process.ipc_waiting = true
                                else
                                    local ret = table.pack(handler.handler(table.unpack(handler_args)))
                                    process.sysret = ret
                                    process.status = "running"
                                    process.ipc_waiting = false
                                end
                            end
                        elseif syscall == "ipc_response" then
                            for _, waiting_proc in ipairs(api.processes) do
                                if waiting_proc.pid == args[1] then
                                    waiting_proc.status = "running"
                                    waiting_proc.sysret = table.pack(table.unpack(args, 2))
                                    break
                                end
                            end
                        elseif syscall == "driver" then
                            local driverAddr = table.remove(args, 1)
                            local driverFunc = table.remove(args, 1)
                            local driverArgs = args

                            local driver = package.require("driver").fromCache(driverAddr)
                            if not driver then
                                process.sysret = table.pack(false, "No")
                                return
                            end

                            local driverFunc = driver[driverFunc]
                            if not driverFunc then
                                process.sysret = table.pack(false, "Driver function not found")
                                return
                            end

                            process.sysret = table.pack(driverFunc(table.unpack(driverArgs)))
                            
                        end
                    end
                end
                
                -- Update CPU times
                local endTime = computer.uptime() * 1000
                process.lastCpuTime = endTime / 1000 - startTime / 1000
                for childIndex, childProcess in ipairs(process.processes) do
                    process.lastCpuTime = process.lastCpuTime + childProcess.lastCpuTime
                end
                usedTime = usedTime + process.lastCpuTime
                table.insert(process.cputime_avg, process.lastCpuTime)
                if #process.cputime_avg > 32 then
                    table.remove(process.cputime_avg, 1)
                end
                return true
            else
                process.status = "idle"
                process.lastCpuTime = 0
                for childIndex, childProcess in ipairs(process.processes) do
                    process.lastCpuTime = process.lastCpuTime + childProcess.lastCpuTime
                end
                usedTime = usedTime + process.lastCpuTime
                table.insert(process.cputime_avg, process.lastCpuTime)
                if #process.cputime_avg > 24 then
                    table.remove(process.cputime_avg, 1)
                end
                return false
            end
        elseif coroutine.status(process.thread) == "dead" then
            process.status = "dying"
            return false
        end
    elseif process.status == "dead" then
        table.insert(toRemoveFromProc, process)
        return false
    elseif process.status == "dying" then
        process.emit("exit")
        local nTerminatedHandles = 0
        for _, stream in ipairs(process.io.handles) do
            stream:close()
            nTerminatedHandles = nTerminatedHandles + 1
        end
        if nTerminatedHandles > 0 then
            printk("Process manager terminated " .. nTerminatedHandles .. " handles for process " .. process.pid, "warn")
        end
        printk("Process with name " .. process.name .. " with pid " .. process.pid .. " has died: " .. process.err)
        process.io.signal.pull = {}
        process.io.signal.queue = {}
        process.err = ""
        process.lastCpuTime = 0
        process.status = "dead"
        return false
    end
    api.currentProcess = nil
end
local idleTimeAvg = {}

api.tick = function()
    local activeProcessCount = 0
    local startTickTime = computer.uptime()
    usedTime = 0

    local function ticker(processes, event)
        local nTicked = 0
        for processIndex, currentProcess in ipairs(processes) do
            activeProcessCount = activeProcessCount + 1
            if #currentProcess.processes > 0 then
                nTicked = nTicked + ticker(currentProcess.processes, event)
            end
            if event[1] == "ipc_response" and currentProcess.ipc_waiting and event[2] == currentProcess.pid then
                printk("Process manager has received an IPC response for a IPC caller process (its fucking kernel side) "..currentProcess.pid)
                currentProcess.status = "running"
                currentProcess.ipc_waiting = false
                currentProcess.sysret = event[3] -- Response args
            elseif event[1] == "ipc_response" then
                printk("Process manager has received an out of context IPC call response for a IPC caller process (kernelside) "..currentProcess.pid)
            end
            local tickResult = api.tickProcess(currentProcess, event)
            if tickResult then
                nTicked = nTicked + 1
            end
        end
        return nTicked
    end
    local event = {computer.pullSignal(0)}

    local nTicks = 0
    local st = computer.uptime()
    while ticker(api.processes, nTicks == 0 and event or {}) > 0 and computer.uptime() - st < 0.05 do
        nTicks = nTicks + 1
    end
    --printk("Process tick took " .. nTicks .. " iters")

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
    local endTickTime = computer.uptime()
    usedTime = 0

    for processIndex, process in ipairs(api.processes) do
        usedTime = usedTime + process.lastCpuTime
    end

    unusedTime = endTickTime - startTickTime
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
