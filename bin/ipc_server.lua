local ipc = require("ipc")
local process = require("process")

ipc.register("test", function()
    return "Hello, World! I am process " .. process.getCurrentProcess().pid, "Here's another arg", "and a third"
end)

while true do
    local event = {computer.pullSignal()}
    ipc.tick_me(event)
end