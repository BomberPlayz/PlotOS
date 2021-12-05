local sec = {}
local procPerms = {}


function sec.attach(proc)
    local process = require("process")
    local ret = {}
    ret.permissions = {}
    function ret.addPermission(perm)
        local proca = process.findByThread(coroutine.running())
        if proca then
            if proca.security.hasPermission("security.permission.add") and proca.security.hasPermission(perm) then
                proc.security.permissions[perm] = true
            end
        end
    end

    function ret.removePermission(perm)
        local proca = process.findByThread(coroutine.running())
        if proca then
            if proca.security.hasPermission("security.permission.remove") then
                proc.security.permissions[perm] = false
            end
        end
    end

    function ret.hasPermission(perm)
        return proc.security.permissions[perm] and proc.security.permissions[perm] or false
    end

    proc.security = ret

    return ret
end

return sec