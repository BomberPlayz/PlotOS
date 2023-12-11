local fs = require("fs")
local event = require("event")
local process = require("process")
local reserveList = {}
event.listen("component_added", function(addr, type)
    if type == "filesystem" then

        
        kern_info("New disk "..addr.." has been found")
        fs.mount(require("driver").load("drive",addr),"/mnt/"..string.sub(addr,1,3))
        kern_info("New disk "..addr.." has been mounted")
    end
end)
event.listen("component_removed", function(addr, type)
    if type == "filesystem" then
        fs.umount(addr)
        kern_info("disk "..addr.." has been unmounted")
    end
end)

process.new("ComponentAdder", [[


for k,v in ipairs(component.list()) do
    local com = component.proxy(k)
    if com then
    computer.pushSignal("component_added",k,com.type)
    end
    os.sleep(0)
end



]])