local process = require("process")
local _pullSignal = computer.pullSignal
computer._signal = {  }
computer.realPullSignal = _pullSignal
computer.pullSignal = function(tout)

    local proc = process.findByThread(coroutine.running())

    if proc then

       -- print("ITS ITITIT")
        coroutine.yield()

        table.insert(proc.io.signal.pull, {timeout=tout or math.huge, start_at=computer.uptime()})
        local ind = #proc.io.signal.pull
        while true do
            if proc.io.signal.pull[ind].ret then
                local a,b,c,d,e,f,g,h,i,j,k = table.unpack(proc.io.signal.pull[ind].ret)
                table.remove(proc.io.signal.pull,ind)
                return a,b,c,d,e,f,g,h,i,j,k
            end
            coroutine.yield()
        end
        --print(table.unpack(computer._signal))

    else
        if not computer._signal then
            computer._signal = table.pack(_pullSignal(tout))
        end
        local a,b,c,d,e,f,g,h,i,j,k = table.unpack(computer._signal)
        return a,b,c,d,e,f,g,h,i,j,k
    end
end 