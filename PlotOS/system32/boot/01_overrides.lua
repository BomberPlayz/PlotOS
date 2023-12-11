local process = require("process")
local _pullSignal = computer.pullSignal
kern_info("Overriding function so process can work")

computer._signal = {  }
computer.realPullSignal = _pullSignal
computer.pullSignal = function(tout)

    local proc = process.findByThread(coroutine.running())

    if proc then
        coroutine.yield()
        -- Insert a new signal with timeout and start time into the process's signal pull
        table.insert(proc.io.signal.pull, {timeout=tout or math.huge, start_at=computer.uptime()})
        local signalIndex = #proc.io.signal.pull
        while true do
            -- If the signal has a return value, unpack it and remove the signal from the pull
            if proc.io.signal.pull[signalIndex].ret then
                local a,b,c,d,e,f,g,h,i,j,k = table.unpack(proc.io.signal.pull[signalIndex].ret)
                table.remove(proc.io.signal.pull, signalIndex)
                return a,b,c,d,e,f,g,h,i,j,k
            end
            coroutine.yield()
        end
    else
        -- If there's no signal, create a new one
        if not computer._signal then
            computer._signal = table.pack(_pullSignal(tout))
        end
        local a,b,c,d,e,f,g,h,i,j,k = table.unpack(computer._signal)
        return a,b,c,d,e,f,g,h,i,j,k
    end
end