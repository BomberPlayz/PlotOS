local stdlib = {}

stdlib.str = {}
stdlib.str.split = function(str, sep)
    sep = sep or "%s"
    local ret, index = {}, 1
    for match in string.gmatch(str, "([^"..sep.."]+)") do
        ret[index] = match
        index = index + 1
    end
    return ret
end

stdlib.str.startswith = function(str, x)
    return str:sub(1, #x) == x
end


return stdlib