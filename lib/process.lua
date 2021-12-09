local api = {}
api.processes = {}
api.signal = {}
local unusedTime = 0
local security = require("security")
local as_pid = 1
local usedTime = 0
local function setfenv(f, env)
    local _ENV = env or {}       -- create the _ENV upvalue
    return function(...)
        print('upvalue', _ENV)   -- address of _ENV upvalue
        return f(...)
    end
end
local _signal = nil





api.findByThread = function(thread)
    -- SHITTY CODE
    for k=1,#api.processes do
        --os.sleep(0)
        local v = api.processes[k]
        --component.gpu.set(1,1,"k: "..k)
        if v.thread == thread then

            return v
        end
        if #v.processes > 0 then
            for k=1,#v.processes do
                --os.sleep(0)
                local v = v.processes[k]
                --component.gpu.set(1,1,"k: "..k)
                if v.thread == thread then

                    return v
                end
                if #v.processes > 0 then
                    for k=1,#v.processes do
                        --os.sleep(0)
                        local v = v.processes[k]
                        --component.gpu.set(1,1,"k: "..k)
                        if v.thread == thread then

                            return v
                        end
                        if #v.processes > 0 then
                            for k=1,#v.processes do
                                --os.sleep(0)
                                local v = v.processes[k]
                                --component.gpu.set(1,1,"k: "..k)
                                if v.thread == thread then

                                    return v
                                end
                                if #v.processes > 0 then
                                    for k=1,#v.processes do
                                        --os.sleep(0)
                                        local v = v.processes[k]
                                        --component.gpu.set(1,1,"k: "..k)
                                        if v.thread == thread then

                                            return v
                                        end
                                        if #v.processes > 0 then
                                            for k=1,#v.processes do
                                                --os.sleep(0)
                                                local v = v.processes[k]
                                                --component.gpu.set(1,1,"k: "..k)
                                                if v.thread == thread then

                                                    return v
                                                end
                                                if #v.processes > 0 then
                                                    for k=1,#v.processes do
                                                        --os.sleep(0)
                                                        local v = v.processes[k]
                                                        --component.gpu.set(1,1,"k: "..k)
                                                        if v.thread == thread then

                                                            return v
                                                        end
                                                        if #v.processes > 0 then
                                                            for k=1,#v.processes do
                                                                --os.sleep(0)
                                                                local v = v.processes[k]
                                                                --component.gpu.set(1,1,"k: "..k)
                                                                if v.thread == thread then

                                                                    return v
                                                                end
                                                                if #v.processes > 0 then
                                                                    for k=1,#v.processes do
                                                                        --os.sleep(0)
                                                                        local v = v.processes[k]
                                                                        --component.gpu.set(1,1,"k: "..k)
                                                                        if v.thread == thread then

                                                                            return v
                                                                        end
                                                                        if #v.processes > 0 then
                                                                            for k=1,#v.processes do
                                                                                --os.sleep(0)
                                                                                local v = v.processes[k]
                                                                                --component.gpu.set(1,1,"k: "..k)
                                                                                if v.thread == thread then

                                                                                    return v
                                                                                end
                                                                                if #v.processes > 0 then
                                                                                    for k=1,#v.processes do
                                                                                        --os.sleep(0)
                                                                                        local v = v.processes[k]
                                                                                        --component.gpu.set(1,1,"k: "..k)
                                                                                        if v.thread == thread then

                                                                                            return v
                                                                                        end
                                                                                        if #v.processes > 0 then
                                                                                            for k=1,#v.processes do
                                                                                                --os.sleep(0)
                                                                                                local v = v.processes[k]
                                                                                                --component.gpu.set(1,1,"k: "..k)
                                                                                                if v.thread == thread then

                                                                                                    return v
                                                                                                end
                                                                                                if #v.processes > 0 then
                                                                                                    for k=1,#v.processes do
                                                                                                        --os.sleep(0)
                                                                                                        local v = v.processes[k]
                                                                                                        --component.gpu.set(1,1,"k: "..k)
                                                                                                        if v.thread == thread then

                                                                                                            return v
                                                                                                        end
                                                                                                        if #v.processes > 0 then
                                                                                                            for k=1,#v.processes do
                                                                                                                --os.sleep(0)
                                                                                                                local v = v.processes[k]
                                                                                                                --component.gpu.set(1,1,"k: "..k)
                                                                                                                if v.thread == thread then

                                                                                                                    return v
                                                                                                                end
                                                                                                                if #v.processes > 0 then
                                                                                                                    for k=1,#v.processes do
                                                                                                                        --os.sleep(0)
                                                                                                                        local v = v.processes[k]
                                                                                                                        --component.gpu.set(1,1,"k: "..k)
                                                                                                                        if v.thread == thread then

                                                                                                                            return v
                                                                                                                        end
                                                                                                                        if #v.processes > 0 then
                                                                                                                            for k=1,#v.processes do
                                                                                                                                --os.sleep(0)
                                                                                                                                local v = v.processes[k]
                                                                                                                                --component.gpu.set(1,1,"k: "..k)
                                                                                                                                if v.thread == thread then

                                                                                                                                    return v
                                                                                                                                end
                                                                                                                                if #v.processes > 0 then
                                                                                                                                    for k=1,#v.processes do
                                                                                                                                        --os.sleep(0)
                                                                                                                                        local v = v.processes[k]
                                                                                                                                        --component.gpu.set(1,1,"k: "..k)
                                                                                                                                        if v.thread == thread then

                                                                                                                                            return v
                                                                                                                                        end
                                                                                                                                        if #v.processes > 0 then
                                                                                                                                            for k=1,#v.processes do
                                                                                                                                                --os.sleep(0)
                                                                                                                                                local v = v.processes[k]
                                                                                                                                                --component.gpu.set(1,1,"k: "..k)
                                                                                                                                                if v.thread == thread then

                                                                                                                                                    return v
                                                                                                                                                end
                                                                                                                                                if #v.processes > 0 then
                                                                                                                                                    for k=1,#v.processes do
                                                                                                                                                        --os.sleep(0)
                                                                                                                                                        local v = v.processes[k]
                                                                                                                                                        --component.gpu.set(1,1,"k: "..k)
                                                                                                                                                        if v.thread == thread then

                                                                                                                                                            return v
                                                                                                                                                        end
                                                                                                                                                        if #v.processes > 0 then
                                                                                                                                                            for k=1,#v.processes do
                                                                                                                                                                --os.sleep(0)
                                                                                                                                                                local v = v.processes[k]
                                                                                                                                                                --component.gpu.set(1,1,"k: "..k)
                                                                                                                                                                if v.thread == thread then

                                                                                                                                                                    return v
                                                                                                                                                                end
                                                                                                                                                                if #v.processes > 0 then
                                                                                                                                                                    for k=1,#v.processes do
                                                                                                                                                                        --os.sleep(0)
                                                                                                                                                                        local v = v.processes[k]
                                                                                                                                                                        --component.gpu.set(1,1,"k: "..k)
                                                                                                                                                                        if v.thread == thread then

                                                                                                                                                                            return v
                                                                                                                                                                        end
                                                                                                                                                                        if #v.processes > 0 then
                                                                                                                                                                            for k=1,#v.processes do
                                                                                                                                                                                --os.sleep(0)
                                                                                                                                                                                local v = v.processes[k]
                                                                                                                                                                                --component.gpu.set(1,1,"k: "..k)
                                                                                                                                                                                if v.thread == thread then

                                                                                                                                                                                    return v
                                                                                                                                                                                end
                                                                                                                                                                                if #v.processes > 0 then

                                                                                                                                                                                end

                                                                                                                                                                            end
                                                                                                                                                                        end

                                                                                                                                                                    end
                                                                                                                                                                end

                                                                                                                                                            end
                                                                                                                                                        end

                                                                                                                                                    end
                                                                                                                                                end

                                                                                                                                            end
                                                                                                                                        end

                                                                                                                                    end
                                                                                                                                end

                                                                                                                            end
                                                                                                                        end

                                                                                                                    end
                                                                                                                end

                                                                                                            end
                                                                                                        end

                                                                                                    end
                                                                                                end

                                                                                            end
                                                                                        end

                                                                                    end
                                                                                end

                                                                            end
                                                                        end

                                                                    end
                                                                end

                                                            end
                                                        end

                                                    end
                                                end

                                            end
                                        end

                                    end
                                end

                            end
                        end

                    end
                end

            end
        end

    end
end

api.isProcess = function()
    if api.findByThread(coroutine.running()) then
        return true
    end
end


api.new = function(name, code, perms,forceRoot,...)


    local ret = {}







    --env._G = env
    --print(code)

    local code = load(code, "=" .. name, nil,_G)
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
    as_pid = as_pid+1

    function ret:getCpuTime()
        return ret.lastCpuTime
    end

    function ret:getCpuPercentage()
        local allcputime = 0
        for k,v in ipairs(api.list()) do
            allcputime = allcputime + v:getCpuTime()
        end
        return ret.lastCpuTime > 0 and (ret.lastCpuTime / allcputime*100) or 0

    end

    function ret:getAvgCpuTime()
        local rama = 0
        for k,v in ipairs(ret.cputime_avg) do
            rama = rama+v
        end
        rama = rama/#ret.cputime_avg
        return rama
    end

    function ret:getAvgCpuPercentage()
        local allcputime = 0
        for k,v in ipairs(api.list()) do
            allcputime = allcputime + v:getAvgCpuTime()
        end
        allcputime = allcputime + api.getAvgIdleTime()
        return ret:getAvgCpuTime() > 0 and (ret:getAvgCpuTime() / allcputime*100) or 0
    end

    function ret:kill()
        self.status = "dying"

    end

    function ret:terminate()
        self.status = "dead"

    end
    security.attach(ret)

    if api.isProcess() and not forceRoot then
        local p = api.findByThread(coroutine.running())
        table.insert(p.processes,ret)
        ret.parent = p
    else
        table.insert(api.processes,ret)
    end



    return ret
end

api.load = function(name, path, perms, forceRoot,...)
    local fs = require("fs")
    --kern_info("loaded fs")
    if path:sub(1,1) ~= "/" then
        path = (os.currentDirectory or "/") .. "/" .. path
    end
    -- kern_info("opening")
    local handle, open_reason = fs.open(path)
    -- kern_info("opened")
    if not handle then
        return nil, open_reason
    end
    local buffer = {}
    while true do
        -- kern_info("read")
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
    return api.new(name,table.concat(buffer),perms,forceRoot,...)
end

local toRemoveFromProc = {}

-- print(coroutine.status(v.thread))
api.tickProcess = function(v)

    --if math.random(1,10000) > 9500 then print("Name: "..v.name.." status: "..v.status) end
    if (v.status == "running" or v.status == "idle") then

        if coroutine.status(v.thread) == "suspended" then
          --  print(tostring(#v.io.signal.pull))
            --setfenv(v.thread, env)
            if #v.io.signal.pull > 0 then
                --print("It wants")
                if not v.io.signal.queue[1] then

                    local a,b,c,d,e,f,g,aa,ss = computer.pullSignal(0)
                    if a then
                      --  print("BIT IT SIG")
                        table.insert(v.io.signal.queue, { a,b,c,d,e,f,g,aa,ss })
                    end
                end
                local puk = v.io.signal.pull[#v.io.signal.pull]
                if type(v.io.signal.queue[1]) == "table" and v.io.signal.queue[1][1] or (computer.uptime() >= puk.timeout + puk.start_at) then
                    v.status = "running"
                    --print(tostring(v.io.signal.queue[1][1]))
                    v.io.signal.pull[#v.io.signal.pull].ret = v.io.signal.queue[1] or {}
                    if v.io.signal.queue[1] then
                        table.remove(v.io.signal.queue,1)
                    end
                    local st = computer.uptime()*1000
                    local reta, ee = coroutine.resume(v.thread, table.unpack(v.args))
                    if not reta then
                        v.err = ee or "Died"
                    end
                    local et = computer.uptime()*1000
                    v.lastCpuTime = et/1000-st/1000
                    for kk,vv in ipairs(v.processes) do
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
                    for kk,vv in ipairs(v.processes) do
                        v.lastCpuTime = v.lastCpuTime + vv.lastCpuTime

                    end
                    usedTime = usedTime + v.lastCpuTime
                    table.insert(v.cputime_avg, v.lastCpuTime)
                    if #v.cputime_avg > 24 then
                        table.remove(v.cputime_avg, 1)
                    end
                end
            else
                local a,b,c,d,e,f,g,aa,ss = computer.pullSignal(0)
              --  print(tostring(a))
                if a then
                    table.insert(v.io.signal.queue, { a,b,c,d,e,f,g,aa,ss })
                end

                local st = computer.uptime()*1000
                local reta, ee = coroutine.resume(v.thread, table.unpack(v.args))
                if not reta then
                    v.err = ee or "Died"
                end
                local et = computer.uptime()*1000
                v.lastCpuTime = et/1000-st/1000
                for kk,vv in ipairs(v.processes) do
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
       -- print(v.name.." dead: "..v.err)

        v.io.signal.pull = {}
        v.io.signal.queue = {}
        v.err = ""
        v.lastCpuTime = 0
        v.status = "dead"

    end
end
local idleTimeAvg = {}



api.tick = function()
    local ae = 0
    local s = computer.uptime()
    usedTime = 0
    
    local function ticker(processes)
        for k,v in ipairs(processes) do
            ae = ae+1
            if #v.processes > 0 then
                --print(#v.processes)
                ticker(v.processes)

            end
            local a,e = api.tickProcess(v)


            --ticker(v.processes)
           -- print(v.name)

        end

    end
    ticker(api.processes)
    
    for k,v in ipairs(toRemoveFromProc) do

        if not v.parent then
            for i=1,#api.processes do
                if api.processes[i].pid == v.pid then
                    table.remove(api.processes, i)
                    break
                end

            end
        else
            for i=1, #v.parent.processes do
                if v.parent.processes[i].pid == v.pid then
                    table.remove(v.parent.processes, i)
                    break
                end
            end
        end

    end
    local e = computer.uptime()
    usedTime = 0
    for k,v in ipairs(api.processes) do
        usedTime = usedTime + v.lastCpuTime
    end
    unusedTime = e-s
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
    for k,v in ipairs(api.processes) do
        allUsed = allUsed + v.getCpuTime()
    end
    allUsed = allUsed+api.getIdleTime()
    return allUsed > 0 and (api.getIdleTime() / allUsed * 100) or 100
end

api.getAvgIdleTime = function()
    local rata = 0
    for k,v in ipairs(idleTimeAvg) do
        rata = rata+v
    end
    rata = rata/#idleTimeAvg
    return rata
end

api.getAvgIdlePercentage = function()
    local allUsed = 0
    for k,v in ipairs(api.processes) do
        allUsed = allUsed + v.getAvgCpuTime()
    end
    allUsed = allUsed+api.getAvgIdleTime()
    return allUsed > 0 and (api.getAvgIdleTime() / allUsed * 100) or 100
end


api.autoTick = function()
    local lastTick = 0
    while true do
        lastTick = lastTick+1

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
    for k,v in ipairs(api.processes) do
        if string.match(v.name, filter or "") then
            table.insert(ret, v)
        end
    end
    return ret
end


return api