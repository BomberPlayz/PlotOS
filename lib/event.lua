local event = {}
local proc = require("process")
-- event#pull function. Takes a timeout and an event.
-- Use computer.pullSignal to get an event. It takes a timeout as argument.
-- If the timeout is nil, the function will block until an event occurs.
-- an event may have unlimited arguments, they should be returned as-is, not in a table.
-- if no timeout is specified, event.pull should wait until a correct event occurs. If there is a timeout, then event.pull should return nil if no event occurs before the timeout.
function event.pull(event, timeout)
    if type(event) == "number" then
        timeout = event
        event = nil
    end
    local evt = event
    if not timeout then
        timeout = math.huge
    end
    if timeout < 0.05 then
        timeout = 0.05
    end


    local f = true

    local start = computer.uptime()
    while (computer.uptime() - start < timeout) or f do
        -- f = false
        local evente = { computer.pullSignal(timeout - (computer.uptime() - start)) }
        --local sig, a, b, c, d, e, f = computer.pullSignal(timeout-(computer.uptime()-timeout)
        if evente[1] == evt or evt == nil then
            return table.unpack(evente)
        end
    end
    return nil
end

function event.push(name, ...)
    computer.pushSignal(name, ...)
end

function event.listen(event, callback)
    local process = require("process")
    process.load("eventlistener-" .. event .. "-" .. math.floor(math.random(1, 999999999)), "/lib/event_listener.lua",
        nil, nil, event, callback)
end

function event.emitter()
    local obj = {}

    obj.internal = {}
    obj.internal.listeners = {}

    obj.on = function(evt, callback)
        table.insert(obj.internal.listeners, {
            event = evt,
            callback = callback,
            doDestroy = false
        })
    end

    obj.once = function(evt, callback)
        table.insert(obj.internal.listeners, {
            event = evt,
            callback = callback,
            doDestroy = true
        })
    end

    obj.emit = function(evt, ...)
        local args = { ... }
        for k, v in ipairs(obj.internal.listeners) do
            if v.event == evt then
                v.callback(table.unpack(args))
                if v.doDestroy then
                    table.remove(obj.internal.listeners, k)
                end
            end
        end
    end

    obj.remove = function(evt, callback)
        for k, v in ipairs(obj.internal.listeners) do
            if v.event == evt and v.callback == callback then
                table.remove(obj.internal.listeners, k)
            end
        end
    end

    return obj
end

event.timeouts = {}

function event.setTimeout(fun, timeout)
    table.insert(event.timeouts, {
        timeout = timeout,
        callback = fun,
        start = computer.uptime(),
        isInterval = false
    })
end

function event.setInterval(fun, timeout)
    table.insert(event.timeouts, {
        timeout = timeout,
        callback = fun,
        start = computer.uptime(),
        isInterval = false
    })
end

printk("Loading timeout handler")
proc.new("TimeoutHandler", [[

local event = require("event")

while true do
  os.sleep()
  for k,v in ipairs(event.timeouts) do
    if computer.uptime() - v.start >= v.timeout then
      v.callback()
      if not v.isInterval then
        table.remove(event.timeouts, k)
      else
        v.start = computer.uptime()
      end
    end
  end
end

]])

printk("Loading DONE handler")
return event
