local kernel = require("kernel")
local fs = require("fs")

local log_file = fs.open("/journal.log", "a")
--- @type Stream
local log_handle = kernel.createLogReader()

printk("Journal daemon started")

while true do
    os.sleep(0.5)
    local d = log_handle:read(math.huge)
    if d then
        log_file:write(d)
    end
end