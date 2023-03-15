local args = ...
local cmd = args[2]
local fs = require("fs")
local process = require("process")
table.remove(args,1)
local proc = nil

if fs.exists("/bin/"..cmd..".lua") then
    proc = process.load(cmd, "/bin/"..cmd..".lua",nil,nil,args)


else
    if fs.exists(os.currentDirectory..cmd) then
        --dofile(os.currentDirectory..cmd)
        proc = process.load(cmd,os.currentDirectory..cmd,nil,nil,args)
    else
        print("The specified file does not exist")
    end
end

--[[local noco = 0
while true do
    if #proc.processes < 1 then
        noco = noco + 1
    else
        noco = 0
    end

    if noco > 10 then
        break
    end
    computer.pullSignal(0)
end]]