print("PlotOS")
print("Testing beta")
local std = require("stdlib")
local fs = require("fs")
os.setEnv("computerName","PlotOS")
os.setEnv("user","guest")
os.currentDirectory = "/"

local gpu = require("driver").load("gpu")

local function canonicalizePath(p)
    local path = std.str.split(p, "/")

    local r = {}
    if p:sub(1,1) ~= "/" then
        r = std.str.split(os.currentDirectory, "/")
    end
    
    for i,v in ipairs(path) do
        if v == "." then
            
        elseif v == ".." then
            table.remove(r, #r)
        else
            table.insert(r, v)
        end
    end

    return "/"..table.concat(r,"/")
end

while true do
    gpu.setForeground(0x00FF00)
    io.write(os.getEnv("user").."@"..os.getEnv("computerName")..":")
    gpu.setForeground(0x2fa1c6)
    io.write(os.currentDirectory.."$ ")
    local cmd = io.read()
    local args = std.str.split(cmd, " ")
    cmd = args[1]

    if cmd == "cd" then
        local path = args[2] and canonicalizePath(tostring(args[2])) or "/"
        if not fs.exists(path) then
            print("shell: cannot access '"..args[2].."': No such file or directory")
        else
            os.currentDirectory = path
        end
    elseif cmd and #cmd ~= 0 then
        local binPath

        if string.find(cmd, "/") then
            local x = canonicalizePath(cmd)

            if fs.exists(x) then
                binPath = x
            end
        else
            local PATH = std.str.split(os.getEnv("PATH"), ";")
            for i,v in ipairs(PATH) do
                if fs.exists(v.."/"..cmd) then
                    binPath = v.."/"..cmd
                    break
                elseif fs.exists(v.."/"..cmd..".lua") then
                    binPath = v.."/"..cmd..".lua"
                    break     
                end
            end
        end

        if not binPath then
            print("shell: "..cmd..": command not found")
        else
            local l, err = loadfile(binPath)

            if not l then
                gpu.setForeground(0xFF0000)
                print(tostring(err))
                gpu.setForeground(0xFFFFFF)
            else
                local s, err = pcall(l, args)
                if not s then
                    gpu.setForeground(0xFF0000)
                    print(tostring(err))
                    gpu.setForeground(0xFFFFFF)
                end
            end
        end

        local path = os.getEnv("PATH")
        local paths = std.str.split(path,";")
        local found = false
        local dat, reason
        for k,v in ipairs(paths) do
            if fs.exists(v.."/"..cmd) then
                dat, reason = loadfile(v.."/"..cmd)
                found = true
                break
            elseif fs.exists(v.."/"..cmd..".lua") then
                dat, reason = loadfile(v.."/"..cmd)
                found = true
                break
            end
        end
    end
end