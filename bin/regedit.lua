local reg = package.require("registry")
local std = package.require("stdlib")

while true do
    io.write("regedit> ")
    local cmd = io.read()
    local args = std.str.split(cmd, " ")
    cmd = args[1]
    table.remove(args, 1)
    if cmd == "set" then
        local path = args[1]
        local value = args[2]
        local data = args[3]
        if not path or not value or not data then
            print("Usage: set <path> <value> <type>")
        else
            reg.set(path, value, reg.types[data] or reg.types.string)
        end
    elseif cmd == "get" then
        local path = args[1]
        local value = args[2]
        if not path or not value then
            print("Usage: get <path> <type>")
        else
            local data = reg.get(path, reg.types[value] or reg.types.string)
            if data then
                print(data)
            else
                print("No such value")
            end
        end
    elseif cmd == "list" then
        local path = args[1]
        if not path then
            print("Usage: list <path>")
        else
            local data = reg.list(path)
            if data then
                for k,v in pairs(data) do
                    local strType = tostring(v)
                    for k2,v2 in pairs(reg.types) do
                        if v2 == v then
                            strType = k2
                            break
                        end
                    end

                    print(string.format("%s = %s", k, strType))
                end
            else
                print("No such path")
            end
        end
    elseif cmd == "quit" then
        break
    end
end