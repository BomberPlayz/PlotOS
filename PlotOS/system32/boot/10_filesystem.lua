local fs = require("fs")
local event = require("event")
local process = require("process")
local reserveList = {}
event.listen("component_added", function(addr, type)
    if type == "filesystem" then
        local lab = fs.getFreeLabel()
        fs.reserveLabel(lab)
        reserveList[addr] = lab
        fs.mount(require("driver").load("drive",addr),"/"..lab)
    end
end)
event.listen("component_removed", function(addr, type)
    if type == "filesystem" then
        fs.umount(addr)
        fs.freeLabel(reserveList[addr] or "")
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