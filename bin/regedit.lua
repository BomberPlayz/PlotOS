local reg = package.require("registry")

function split(str, sep)
    local ret = {}
    for str in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(ret, str)
    end
    return ret
end

while true do
    io.write("regedit> ")
    local cmd = io.read()
    local args = split(cmd, " ")
    cmd = args[1]
    table.remove(args, 1)
    if cmd == "set" then
        local path = args[1]
        local value = args[2]
        local data = args[3]
        if not path or not value or not data then
            print("Usage: set <path> <value> <type>")
        else
            reg.set(path, value, data or reg.types.string)
        end
    elseif cmd == "get" then
        local path = args[1]
        local value = args[2]
        if not path or not value then
            print("Usage: get <path> <value>")
        else
            local data = reg.get(path, value)
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
                    print(k.." = "..v)
                end
            else
                print("No such path")
            end
        end
    end

end