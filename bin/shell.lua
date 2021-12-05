print("PlotOS")
print("Testing beta")
local fs = require("fs")
_G.computerName = "PlotOS"
os.setEnv("user","guest")
os.currentDirectory = "/"

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


while true do
  component.gpu.setForeground(0x00FF00)
  io.write(os.getEnv("user").."@"..computerName..":")
  component.gpu.setForeground(0x2fa1c6)
  io.write("~"..os.currentDirectory)
  local cmd = io.read()
  local args = split(cmd, " ")
  cmd = args[1]

 -- print('"'..cmd..'"')
  if type(cmd) == "nil" or cmd == "" then else
  if fs.exists("/bin/"..cmd..".lua") then
    local dat,reason = loadfile("/bin/"..cmd..".lua")
    if not dat then
      print("Error: "..reason)
    else
      local ok,reason = pcall(dat,args)
        if not ok then
            print("Errored:")
            print(reason)
        end
    end
    
  else
    if fs.exists(os.currentDirectory..cmd) then
      --dofile(os.currentDirectory..cmd)
      loadfile(os.currentDirectory..cmd)(args)
    else
      print("The specified file does not exist")
    end
  end
  end
  
end