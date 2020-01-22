do
  local addr, invoke = computer.getBootAddress(), component.invoke
  local function loadfile(file)
    local handle = assert(invoke(addr, "open", file))
    local buffer = ""
    repeat
      local data = invoke(addr, "read", handle, math.huge)
      buffer = buffer .. (data or "")
    until not data
    invoke(addr, "close", handle)
    return load(buffer, "=" .. file, "bt", _G)
  end
  loadfile("/lib/core/boot.lua")(loadfile)
end

while true do
  local result, reason = xpcall(require("shell").getShell(), function(msg)
    return tostring(msg).."\n"..debug.traceback()
  end)
  if not result then
    io.stderr:write((reason ~= nil and tostring(reason) or "unknown error") .. "\n")
    local fs = require("filesystem")
    local log
    if not fs.exists("/crashlog.log") then
      log = fs.open("/crashlog.log","w")
    else
      fs.remove("/crashlog.log")
      log = fs.open("/crashlog.log","w")
    end
    
    log:write("---OOPS---\n")
    log:write("PLOTOS HAS CRASHED AND HERE'S A LOG!\n")
    log:write("error of crash:\n")
    log:write(reason ~= nil and tostring(reason) or "unknown error")
    log:write("\nadditional info:\n")
    log:write("is it interrupted: "..string.match(tostring(reason), "interrupted"))
    
    os.sleep(3)
    os.shutdown(1)
  end
end
