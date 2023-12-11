local std = require("stdlib")
local fs = require("fs")

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

local path = canonicalizePath(tostring(({...})[1][2] or os.currentDirectory))

if not fs.exists(path) then
    print("ls: cannot access '"..({...})[1][2]..": No such file or directory")
else
    for name in fs.list(path) do
        if name:sub(#name,#name) == "/" then
            gpu.setForeground(0x0570ee)
        else
            gpu.setForeground(0xffffff)
        end
        print(name)
    end
end