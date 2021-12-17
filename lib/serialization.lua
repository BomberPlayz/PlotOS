local api = {}

api.ini = {}
api.lua = {}
api.json = {}
api.yaml = {}


--[=====================[ INI ]=====================]--
api.ini.encode = function(data)
    -- encode table to ini with section support, but there may not always be section
    local result = ""
    for k, v in pairs(data) do
        if type(v) == "table" then
            result = result .. "[" .. k .. "]\n"
            for k2, v2 in pairs(v) do
                result = result .. k2 .. "=" .. tostring(v2) .. "\n"
            end
        else
            result = result .. k .. "=" .. tostring(v) .. "\n"
        end
    end
    return result


end

api.ini.decode = function(data)
    -- decode ini to table
    local result = {}
    local section = nil
    for line in data:gmatch("[^\r\n]+") do
        if line:sub(1, 1) == "[" and line:sub(-1) == "]" then
            section = line:sub(2, -2)
            result[section] = {}
        else
            local key, value = line:match("^(.+)=(.+)$")
            if key and value then
                result[section][key] = value
            end
        end
    end
    return result
end

--[=====================[ LUA ]=====================]--
api.lua.encode = function(data)
    -- encode table to a string supporting tables in tables
    local result = ""
    local function encode(key,data)
        -- encode table to string
        if type(data) == "table" then
            result = result .. "{"
            for k, v in pairs(data) do
                if type(k) == "number" then
                    result = result .. encode(k, v)
                else
                    result = result .. "[" .. encode(k, v) .. "]"
                end
                result = result .. ","
            end
            result = result .. "}"
        else
            result = result .. "[" .. tostring(key) .. "]" .. "=" .. tostring(data)
        end
    end
    return encode(data)


end

api.lua.decode = function(data)
    -- decode string to lua table supporting every lua type
    local result = {}
    local function decode(data)
        if data:sub(1, 1) == "{" then
            local data = data:sub(2)
            local key, value
            local i = 1
            while true do
                key, value, data = data:match("^%[([^%]]+)%]=(.+)[,}]")
                if key then
                    result[i] = {}
                    result[i][key] = decode(value)
                    i = i + 1
                else
                    break
                end
            end
        elseif data:sub(1, 1) == '"' then
            local data = data:sub(2)
            local key, value
            local i = 1
            while true do
                key, value, data = data:match("^([^\"]+)\"=(.+)[,}]")
                if key then
                    result[i] = {}
                    result[i][key] = value
                    i = i + 1
                else
                    break
                end
            end
        else
            local key, value = data:match("^([^=]+)=(.+)[,}]")
            if key then
                result[key] = decode(value)
            else
                result = data
            end
        end
        return result
    end

end

--[=====================[ JSON ]=====================]--
api.json.encode = function(data)
    -- encode table to json without external libs. Also support json arrays.
    local result = ""
    local function encode(data)
        if type(data) == "table" then
            result = result .. "{"
            local first = true
            for k, v in pairs(data) do
                if first then
                    first = false
                else
                    result = result .. ","
                end
                if type(k) == "number" then
                    result = result .. "[" .. k .. "]"
                else
                    result = result .. "[\"" .. k .. "\"]"
                end
                result = result .. ":"
                encode(v)
            end
            result = result .. "}"
        elseif type(data) == "string" then
            result = result .. "\"" .. data .. "\""
        else
            result = result .. tostring(data)
        end
    end
    encode(data)
    return result

end

api.json.decode = function(data)
    -- decode json without external libs. Also support json arrays.
    local result = {}
    local function decode(data)
        if data:sub(1, 1) == "{" then
            local first = true
            local key = nil
            local value = nil
            for line in data:gmatch("[^,{}]+") do
                if first then
                    first = false
                else
                    if line:sub(1, 1) == ":" then
                        value = line:sub(2)
                    elseif line:sub(1, 1) == "[" then
                        key = tonumber(line:sub(2, -2))
                    else
                        key = line:sub(2, -2)
                    end
                end
            end
            if value:sub(1, 1) == "{" then
                result[key] = decode(value)
            elseif value:sub(1, 1) == "[" then
                result[key] = decode(value)
            elseif value:sub(1, 1) == "\"" then
                result[key] = value:sub(2, -2)
            else
                result[key] = tonumber(value)
            end
        elseif data:sub(1, 1) == "[" then
            local first = true
            local key = nil
            local value = nil
            for line in data:gmatch("[^,{}]+") do
                if first then
                    first = false
                else
                    if line:sub(1, 1) == ":" then
                        value = line:sub(2)
                    elseif line:sub(1, 1) == "[" then
                        key = tonumber(line:sub(2, -2))
                    else
                        key = line:sub(2, -2)
                    end
                end
            end
            if value:sub(1, 1) == "{" then
                result[key] = decode(value)
            elseif value:sub(1, 1) == "[" then
                result[key] = decode(value)
            elseif value:sub(1, 1) == "\"" then
                result[key] = value:sub(2, -2)
            else
                result[key] = tonumber(value)
            end
        elseif data:sub(1, 1) == "\"" then
            result = data:sub(2, -2)
        else
            result = tonumber(data)
        end

    end
    decode(data)
    return result



end

--[=====================[ YAML ]=====================]--
api.yaml.encode = function(data)
    -- encode table to yaml without external libs.
    local result = ""
    local function encode(data)
        if type(data) == "table" then
            result = result .. "---\n"
            for k, v in pairs(data) do
                if type(k) == "number" then
                    result = result .. k .. ": "
                else
                    result = result .. k .. ": "
                end
                encode(v)
            end
        elseif type(data) == "string" then
            result = result .. data .. "\n"
        else
            result = result .. tostring(data) .. "\n"
        end
    end
    encode(data)
    return result
end

api.yaml.decode = function(data)
    -- decode yaml without external libs.
    local result = {}
    local function decode(data)
        if data:sub(1, 3) == "---" then
            local first = true
            local key = nil
            local value = nil
            for line in data:gmatch("[^\n]+") do
                if first then
                    first = false
                else
                    if line:sub(1, 1) == ":" then
                        value = line:sub(2)
                    elseif line:sub(1, 1) == "[" then
                        key = tonumber(line:sub(2, -2))
                    else
                        key = line:sub(2, -2)
                    end
                end
            end
            if value:sub(1, 3) == "---" then
                result[key] = decode(value)
            elseif value:sub(1, 3) == "---" then
                result[key] = decode(value)
            elseif value:sub(1, 1) == "\"" then
                result[key] = value:sub(2, -2)
            else
                result[key] = tonumber(value)
            end
        end
    end
    decode(data)
    return result
end

return api