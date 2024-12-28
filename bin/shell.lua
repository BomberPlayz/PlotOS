local std = require("stdlib")
local fs = require("fs")
local gpu = require("driver").load("gpu")
local process = require("process")
local event   = require("event")
local keyboard= require("keyboard")

-- Initialize environment
local function initEnvironment()
    print("PlotOS")
    print("Testing beta")
    os.setEnv("computerName", "PlotOS")
    os.setEnv("user", "guest")
    os.currentDirectory = "/"
end

-- Path handling
local function canonicalizePath(p)
    local path = std.str.split(p, "/")
    local r = {}
    
    if p:sub(1,1) ~= "/" then
        r = std.str.split(os.currentDirectory, "/")
    end
    
    for _, v in ipairs(path) do
        if v == ".." then
            table.remove(r, #r)
        elseif v ~= "." then
            table.insert(r, v)
        end
    end

    return "/" .. table.concat(r, "/")
end

-- Command execution
local function findExecutable(cmd)
    if string.find(cmd, "/") then
        local fullPath = canonicalizePath(cmd)
        return fs.exists(fullPath) and fullPath or nil
    end

    local PATH = std.str.split(os.getEnv("PATH"), ";")
    for _, dir in ipairs(PATH) do
        local paths = {
            dir .. "/" .. cmd,
            dir .. "/" .. cmd .. ".lua"
        }
        for _, path in ipairs(paths) do
            if fs.exists(path) then
                return path
            end
        end
    end
    return nil
end

local function executeCommand(binPath, args)
    --local program, err = loadfile(binPath)
    local fileHandle = fs.open(binPath, "r")
    if not fileHandle then
        return false, "Failed to open: " .. tostring(err)
    end

    local program = ""
    while true do
        local data, reason = fileHandle:read(1024)
        if not data then
            fileHandle:close()
            if reason then
                return false, "Failed to read: " .. tostring(reason)
            end
            break
        end
        program = program .. data
    end
    --print(program)
    if not program then
        return false, "Failed to load: " .. tostring(err)
    end
    

    local proc = process.new(fs.name(binPath), program, _G, nil, nil, args)
    while proc.status ~= "dead" do
        local e = event.pull(nil, 0)
        if keyboard.isControlDown() and keyboard.isKeyDown("c") then
            printk("Killing process due to user input of ^C")
            proc:terminate()
            print("Killed")
        end
    end

    
    return true
end

local function handleError(message)
    gpu.setForeground(0xFF0000)
    print(tostring(message))
    printk(message)
    gpu.setForeground(0xFFFFFF)
end

-- Command handlers
local commands = {
    cd = function(args)
        local path = args[2] and canonicalizePath(tostring(args[2])) or "/"
        if not fs.exists(path) then
            print("shell: cannot access '" .. args[2] .. "': No such file or directory")
            return
        end
        os.currentDirectory = path
    end
}

-- Main loop
local function main()
    initEnvironment()
    
    local history = {}

    while true do
        -- Display prompt
        gpu.setForeground(0x00FF00)
        io.write(os.getEnv("user") .. "@" .. os.getEnv("computerName") .. ":")
        gpu.setForeground(0x2fa1c6)
        io.write(os.currentDirectory .. "$ ")
        gpu.setForeground(0xFFFFFF)
        
        -- Parse input
        local input = io.read({history = history})
        if not input:match("^%s") then
            table.insert(history, input)
            if #history > 64 then
                table.remove(history, 1)
            end
        end
        local args = std.str.split(input or "", " ")
        local cmd = args[1]
        
        if cmd and #cmd > 0 then
            if commands[cmd] then
                commands[cmd](args)
            else
                local binPath = findExecutable(cmd)
                if not binPath then
                    print("shell: " .. cmd .. ": command not found")
                else
                    local success, err = executeCommand(binPath, args)
                    if not success then
                        handleError("shell: program '" .. cmd .. "' " .. err)
                    end
                end
            end
        end
    end
end


main()