local process = package.require("process")

local ipc = {}
ipc.handlers = {}
ipc.DEFAULT_TIMEOUT = 5 -- seconds

function ipc.call(name, ...)
    if not ipc.handlers[name] then
        return false, "No such handler"
    end

    local ret
    while not ret or ret[1] ~= "ipc_response" do
        ret = table.pack(coroutine.yield("ipc_call", name, table.pack(...)))
    end
    
    
    return table.unpack(ret, 1, ret.n)
end

function ipc.register(name, handler)
    if ipc.handlers[name] then
        return false, "Handler already exists"
    end
    
    local proc = process.getCurrentProcess()
    --if not proc then
    --    return false, "No active process"
    --end
    
    -- Add cleanup hook
    if proc then
        proc:on("exit", function()
            ipc.handlers[name] = nil
        end)
    end
    
    ipc.handlers[name] = {
        handler = handler,
        process = proc,
        registered = computer.uptime()
    }
    return true
end

function ipc.unregister(name)
    if not ipc.handlers[name] then
        return false, "Handler doesn't exist"
    end
    
    local proc = process.getCurrentProcess()
    if proc ~= ipc.handlers[name].process then
        return false, "Not handler owner"
    end
    
    ipc.handlers[name] = nil
    return true
end

-- New helper functions
function ipc.list()
    local handlers = {}
    for name, data in pairs(ipc.handlers) do
        handlers[name] = {
            process = data.process.pid,
            registered = data.registered
        }
    end
    return handlers
end

function ipc.cleanup()
    for name, data in pairs(ipc.handlers) do
        if data.process.status == "dead" then
            ipc.handlers[name] = nil
        end
    end
end

function ipc.tick_me(event)
    if event[1] == "ipc_request" then
        local name = event[2]
        local processe = event[3]
        local args = event[4] or {}
        local handler = ipc.handlers[name]
        if process.currentProcess ~= handler.process then
            kern_log("Process " .. process.currentProcess.pid .. " is trying to call " .. name .. " but it's owned by " .. handler.process.pid..", dropping")
            return false
        end
        local ret = table.pack(handler.handler(table.unpack(args, 1, args.n)))
        if coroutine.isyieldable() then
            coroutine.yield("ipc_response", processe.pid, table.unpack(ret, 1, ret.n))
        else
            return { "ipc_response", processe.pid, table.unpack(ret, 1, ret.n) }
        end
        return true
    end
end

return ipc