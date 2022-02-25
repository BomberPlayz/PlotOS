local sec = {}
local procPerms = {}

local com = component


function sec.attach(proc)
    local process = require("process")
    local ret = {}
    ret.permissions = {
        ["security.permission.add"] = true,
        ["security.permission.remove"] = true
    }

    if proc.parent then
        setmetatable(ret.permissions, {
            __index = function(t, k)
                return proc.parent.permissions[k]
            end
        })
    end

    function ret.addPermission(perm)
        local proca = process.findByThread(coroutine.running())
        if proca then
            if proca.security.hasPermission("security.permission.add") and proca.security.hasPermission(perm) then
                proc.security.permissions[perm] = true
            end
        else
            proc.security.permissions[perm] = true
        end
    end

    function ret.removePermission(perm)
        local proca = process.findByThread(coroutine.running())
        if proca then
            if proca.security.hasPermission("security.permission.remove") and proca.security.hasPermission(perm) then
                proc.security.permissions[perm] = false
            end
        else
            proc.security.permissions[perm] = false
        end
    end

    function ret.hasPermission(perm)
        return proc.security.permissions[perm] and proc.security.permissions[perm] or false
    end

    procPerms[proc.pid] = ret

    proc.security = {
        permissions=procPerms[proc.pid].permissions,
        hasPermission = ret.hasPermission,
    }

    return ret
end

function sec.requestPermission(perm)
    local process = require("process")

    local proca = process.findByThread(coroutine.running())
    if proca then
        if proca.security.hasPermission(perm) then
            return true
        end
    end


end

function sec.hasPermission(perm)
    local process = require("process")

    local proca = process.findByThread(coroutine.running())
    if proca then
        return proca.security.hasPermission(perm)
    end
    return false
end



return sec