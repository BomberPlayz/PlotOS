print("PlotOS")
print("Testing beta")
local fs = require("fs")
os.setEnv("computerName","PlotOS")
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

local gpu = require("driver").load("gpu")
--io.setScreenSize(20,20)
while true do
  gpu.setForeground(0x00FF00)
  io.write(os.getEnv("user").."@"..os.getEnv("computerName")..":")
  gpu.setForeground(0x2fa1c6)
  io.write(os.currentDirectory.."$ ")
  local cmd = io.read()
  local args = split(cmd, " ")
  cmd = args[1]

 -- print('"'..cmd..'"')
  if type(cmd) == "nil" or cmd == "" then else
  --[[if fs.exists("/bin/"..cmd..".lua") then
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
  end]]

      local path = os.getEnv("PATH")
      local paths = split(path,";")
        local found = false
      local dat,reason
        for k,v in ipairs(paths) do
            if fs.exists(v.."/"..cmd..".lua") then
                dat,reason = loadfile(v.."/"..cmd..".lua")
                found = true
                break
            end
        end

        if not found then
            print("Command not found")
        else
            if not dat then
                print("Error: "..reason)
            else
                local ok,reason = pcall(dat,args)
                if not ok then
                    print("Errored:")
                    print(reason)
                end
            end
        end
  end
  
end