local ret = {}
local fs = package.require("fs")
local cp = component
ret.loaded = {}
function ret.getDriver(path)
    if not ret.loaded[path] then
        ret.loaded[path] = raw_dofile("/driver/"..path)
    end
    local d = ret.loaded[path]
    return d
end

function ret.getBest(type, addr)


    for k,v in fs.list("/driver/"..type) do
        local d = ret.getDriver(type.."/"..k)
        if d.compatible(addr) then
            return d
        end
    end


end

function ret.getDefault(type)
    local defa = nil

    for k,v in pairs(cp.list()) do
        local d = ret.getBest(type, k)
        if d then
            return d,k
        end
    end

    return defa
end

function ret.load(type, addr)
    if not addr then addr = "default" end

    if addr == "default" then
        local d,addra = ret.getDefault(type)
        if d then
            local dd = d.new(addra)
            dd.getDriverName = d.getName
            dd.getDriverVersion = d.getDriverVersion
            dd.address = addra
            return d.new(addra)
        else
            return nil, "No drivers found"
        end
    else
        local d = ret.getBest(type, addr)
        if d then
            local dd = d.new(addr)
            dd.getDriverName = d.getName
            dd.getDriverVersion = d.getVersion
            dd.address = addr
            return dd
        else
            return nil, "No drivers found"
        end
    end

end

return ret