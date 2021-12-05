_G.os = {}

os.env = {}

function os.sleep(timeout)
  checkArg(1, timeout, "number", "nil")
  local deadline = computer.uptime() + (timeout or 0)
  repeat
    computer.pullSignal(deadline - computer.uptime())
  until computer.uptime() >= deadline
end

function os.setEnv(env,file)
  checkArg(1,env,"string")
  checkArg(1,file,"string")
  os.env[env] = file
end

function os.getEnv(env)
  checkArg(1,env,"string")
  return os.env[env]
end

os.setEnv("SHELL","/bin/shell.lua")
os.setEnv("BOOT","/sys/system32")
