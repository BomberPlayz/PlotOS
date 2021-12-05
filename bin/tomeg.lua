local com = require("component")
local printer = com.openprinter

local title,data = printer.scan()

for i=1,100,1 do
    printer.setTitle("copy of: "..title)
    local le = -1
    for k,v in pairs(data) do
        le = le+1
    end
    for i=0,le,1 do
        printer.writeln(data[i])
    end
    printer.writeln("this is a copy of: "..title)
    printer.print()
end