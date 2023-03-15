local args = ...
local dir = args[2]
local fs = require("fs")
function split (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

if fs.exists(os.currentDirectory..dir) then
  os.currentDirectory = require("old_fs").normalize(os.currentDirectory..dir).."/"
  print("")
else
  print("This directory doesn't exist!")
end