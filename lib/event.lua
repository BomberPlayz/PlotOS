local event = {}

-- event#pull function. Takes a timeout and an event.
-- Use computer.pullSignal to get an event. It takes a timeout as argument.
-- If the timeout is nil, the function will block until an event occurs.
-- an event may have unlimited arguments, they should be returned as-is, not in a table.
-- if no timeout is specified, event.pull should wait until a correct event occurs. If there is a timeout, then event.pull should return nil if no event occurs before the timeout.
function event.pull(event, timeout)
  local evt = event


  while true do
    local sig, a, b, c, d, e, f = computer.pullSignal(timeout)
    if sig == evt or evt == nil then
      return sig, a, b, c, d, e, f
    end
  end





end

function event.push(name,...)
  computer.pushSignal(name,...)
end

function event.listen(event, callback)
  local process = require("process")
  process.load("eventlistener-"..event.."-"..math.floor(math.random(1,999999999)), "/lib/event_listener.lua", nil, event, callback )
end

function event.emitter()
  local obj = {}

  obj.internal = {}
  obj.internal.listeners = {}

  obj.on = function(evt, callback)
    table.insert(obj.internal.listeners,{
      event=evt,
      callback=callback,
      doDestroy = false
    })
  end

  obj.once = function(evt, callback)
    table.insert(obj.internal.listeners,{
      event=evt,
      callback=callback,
      doDestroy = true
    })
  end

  obj.emit = function(evt,...)
    local args = {...}
    for k,v in ipairs(obj.internal.listeners) do
      if v.event == evt then
        v.callback(table.unpack(args))
        if v.doDestroy then
          table.remove(obj.internal.listeners, k)
        end
      end
    end
  end

  return obj
end

return event