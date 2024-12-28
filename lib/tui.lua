local tui = {}

function tui.prompt(prompt)
    io.write(prompt)
    return io.read()
end

function tui.promptBool(prompt,default)
    io.write(prompt.." ["..(default and "Y/n" or "y/N").."]: ")
    local response = io.read()
    if response == "" then
        return default
    end
    return response[1] == "y" or response[1] == "Y"
end

function tui.promptNumber(prompt,default)
    io.write(prompt.." ["..default.."]: ")
    local response = io.read()
    if response == "" then
        return default
    end
    return tonumber(response) or default
end

function tui.promptString(prompt,default)
    io.write(prompt.." ["..default.."]: ")
    local response = io.read()
    if response == "" then
        return default
    end
    return response
end

return tui