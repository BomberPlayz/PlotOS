local com = require("component")
local printer = com.openprinter

io.write("title> ")
local title = io.read()

while true do
    io.write("text or write .end to print .cancel to cancel> ")
    local line = io.read()
    if line == ".end" then
        printer.setTitle(title)
        printer.print()
        break
    else
        if line == ".cancel" then
            break
        else
            printer.writeln(line)
        end
    end
end