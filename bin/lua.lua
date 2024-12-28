local gpu = require("driver").load("gpu")

local function prettyPrint(value, visited)
    visited = visited or {}
    
    if type(value) == "table" and not visited[value] then
        visited[value] = true
        local items = {}
        local isArray = #value > 0
        local result = "{"
        
        -- Handle array part first
        for i=1, #value do
            local val = value[i]
            table.insert(items, prettyPrint(val, visited))
        end
        
        -- Handle hash part
        for k, v in pairs(value) do
            if type(k) ~= "number" or k > #value then
                local key = type(k) == "string" and k:match("^[%a_][%w_]*$") 
                    and k or "[" .. prettyPrint(k, visited) .. "]"
                table.insert(items, key .. " = " .. prettyPrint(v, visited))
            end
        end
        
        result = result .. table.concat(items, ", ") .. "}"
        return result
    else
        local str = tostring(value)
        if type(value) == "string" then
            str = string.format("%q", value)
        end
        return str
    end
end

local function printColor(color, ...)
    local prevColor = gpu.setForeground(color)
    print(...)
    gpu.setForeground(prevColor)
end

-- Create environment that inherits from _G
local env = setmetatable({}, {__index = _G})

local chunkId = 1
local function smartEval(code)
    -- First try as expression
    local f, err = load("return " .. code, "=lua["..chunkId.."]", "t", env)
    chunkId = chunkId + 1

    if not f then
        -- If that fails, try as statement
        f, err = load(code, "=input", "t", env)
        if not f then
            printColor(0xff0000, tostring(err))
        end
    end
    
    local results = table.pack(pcall(f))
    if not results[1] then
        printColor(0xff0000, tostring(results[2]))
    else
        for i=2, results.n do
            if type(results[i]) == "string" then
                printColor(0xff4433, prettyPrint(results[i]))
            elseif type(results[i]) == "number" then
                printColor(0x66ee66, prettyPrint(results[i]))
            elseif type(results[i]) == "nil" then
                printColor(0x888888, prettyPrint(results[i]))
            elseif type(results[i]) == "boolean" then
                printColor(0x888888, prettyPrint(results[i]))
            elseif type(results[i]) == "table" then
                printColor(0xcccccc, prettyPrint(results[i]))
            else
                printColor(0xffffff, prettyPrint(results[i]))
            end
        end
    end
end

local lines = {}
local prompt = "> "
local multiline = false

local history = {}

while true do
    io.write(prompt)
    local line = io.read({history = history})
    
    if not line or line == "exit" then
        break
    end

    if line:match("[^%s]") then
        table.insert(history, line)
        if #history > 64 then
            table.remove(history, 1)
        end
    end
    
    if multiline then
        if line == "" then
            local code = table.concat(lines, "\n")
            smartEval(code)
            lines = {}
            multiline = false
            prompt = "> "
        else
            table.insert(lines, line)
        end
    else
        if line:sub(-1) == "\\" then
            multiline = true
            prompt = ">> "
            table.insert(lines, line:sub(1, -2))
        else
            smartEval(line)
        end
    end
end
