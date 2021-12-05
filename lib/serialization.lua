local api = {}

function api.serialize (tabl, indent)
    indent = indent and (indent.."  ") or ""
    local str = ''
    str = str .. indent.."{"
    for key, value in pairs (tabl) do
        local pr = (type(key)=="string") and ('["'..key..'"]=') or ""
        if type (value) == "table" then
            str = str..pr..api.serialize (value, indent)
        elseif type (value) == "string" then
            str = str..indent..pr..'"'..tostring(value)..'",'
        else
            str = str..indent..pr..tostring(value)..','
        end
    end
    str = str .. indent.."},"
    return str
end

return api