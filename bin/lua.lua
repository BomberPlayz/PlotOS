local function prettyPrint(value, indent, visited)
    visited = visited or {}
    indent = indent or ""
    
    if type(value) == "table" and not visited[value] then
        visited[value] = true
        local items = {}
        local isArray = #value > 0
        local result = "{\n"
        
        -- Handle array part first
        for i=1, #value do
            local val = value[i]
            table.insert(items, indent .. "  " .. prettyPrint(val, indent .. "  ", visited))
        end
        
        -- Handle hash part
        for k, v in pairs(value) do
            if type(k) ~= "number" or k > #value then
                local key = type(k) == "string" and k:match("^[%a_][%w_]*$") 
                    and k or "[" .. prettyPrint(k, "", visited) .. "]"
                table.insert(items, indent .. "  " .. key .. " = " .. prettyPrint(v, indent .. "  ", visited))
            end
        end
        
        result = result .. table.concat(items, ",\n") .. "\n" .. indent .. "}"
        return result
    else
        local str = tostring(value)
        if type(value) == "string" then
            str = string.format("%q", value)
        end
        return str
    end
end

local function formatOutput(...)
    local args = table.pack(...)
    if args.n == 0 then return "" end
    
    local result = {}
    for i=1, args.n do
        if args[i] ~= nil then
            table.insert(result, prettyPrint(args[i]))
        end
    end
    
    return #result > 0 and table.concat(result, "  ") or "nil"
end

-- Create environment that inherits from _G
local env = setmetatable({}, {__index = _G})

local function smartEval(code)
    -- First try as expression
    local f, err = load("return " .. code, "=input", "t", env)
    if not f then
        -- If that fails, try as statement
        f, err = load(code, "=input", "t", env)
        if not f then
            return false, "Syntax error: " .. tostring(err)
        end
    end
    
    local results = table.pack(pcall(f))
    if not results[1] then
        return false, "Runtime error: " .. tostring(results[2])
    end
    
    -- Remove success boolean
    table.remove(results, 1)
    
    -- Only return non-nil results
    local validResults = {}
    local count = 0
    for i=1, results.n do
        if results[i] ~= nil then
            count = count + 1
            validResults[count] = results[i]
        end
    end
    validResults.n = count
    
    if count > 0 then
        return true, table.unpack(validResults, 1, count)
    end
    return true
end

local lines = {}
local prompt = "> "
local multiline = false

while true do
    io.write(prompt)
    local line = io.read()
    
    if not line or line == "exit" then
        break
    end
    
    if multiline then
        if line == "" then
            local code = table.concat(lines, "\n")
            local ok, result = smartEval(code)
            if ok then
                if result ~= nil then
                    print(formatOutput(result, select(2, result)))
                end
            else
                print(result)
            end
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
            local ok, result = smartEval(line)
            if ok then
                if result ~= nil then
                    print(formatOutput(result, select(2, result)))
                end
            else
                print(result)
            end
        end
    end
end
