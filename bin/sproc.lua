local args = ...
local cmd = args[2]
local fs = require("fs")
local process = require("process")
table.remove(args,1)
if fs.exists("/bin/"..cmd..".lua") then
    process.load(cmd, "/bin/"..cmd..".lua")


else
    if fs.exists(os.currentDirectory..cmd) then
        --dofile(os.currentDirectory..cmd)
        loadfile(os.currentDirectory..cmd)(args)
    else
        print("The specified file does not exist")
    end
end
