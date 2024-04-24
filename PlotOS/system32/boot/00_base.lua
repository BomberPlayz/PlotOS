kern_log("Loading base components")

_G.require = package.require
_G.prt_x = 1
_G.prt_y = 1

_G.print = function(...)
    local t = {}

    for i, v in ipairs({ ... }) do
        t[i] = tostring(v)
    end

    io.writeline(table.concat(t, "    "))
end

_G.printf = function(format, ...)
    _G.print(string.format(format, ...))
end

local fs = require("fs")

function _G.loadfile(filename, ...)
    --kern_info("loaded fs")
    if filename:sub(1, 1) ~= "/" then
        filename = (os.currentDirectory or "/") .. "/" .. filename
    end
    -- kern_info("opening")
    local handle, open_reason = fs.open(filename)
    -- kern_info("opened")
    if not handle then
        return nil, open_reason
    end
    local buffer = {}
    while true do
        -- kern_info("read")
        local data, reason = handle:read(1024)
        if not data then
            handle:close()
            if reason then
                return nil, reason
            end
            break
        end
        buffer[#buffer + 1] = data
    end
    return load(table.concat(buffer), "=" .. filename, ...)
end

function _G.dofile(filename)
    local program, reason = loadfile(filename)
    if not program then
        return error('Dofile error: ' .. reason .. ': ' .. filename, 0)
    end
    return program()
end
