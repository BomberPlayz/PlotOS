local security = require("security")
local oldOS = _G.os
_G.os = {}

os.env = {}

function os.sleep(timeout)
    checkArg(1, timeout, "number", "nil")
    local deadline = computer.uptime() + (timeout or 0)
    repeat
        computer.pullSignal(deadline - computer.uptime())
    until computer.uptime() >= deadline
end

function os.setEnv(env, file)
    printk("Enviornment variable " .. env .. " has been set to " .. file)
    checkArg(1, env, "string")
    checkArg(1, file, "string")
    os.env[env] = file
end

function os.getEnv(env)
    checkArg(1, env, "string")
    return os.env[env]
end

function os.requestPermission(perm)
    checkArg(1, perm, "string")
end

-- functions from old os
os.clock = oldOS.clock
os.date = oldOS.date
os.difftime = oldOS.difftime
os.time = oldOS.time

os.setEnv("SHELL", require("registry").get("/system/shell"))
os.setEnv("BOOT", "/sys/system32")
os.setEnv("PATH", "/bin")
os.setEnv("LIB_PATH", "/lib")
