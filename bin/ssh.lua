local args = ...
local server = args[1] or "crackpixel.hu"
local port = args[2] or 22


local internet = require("driver").load("internet")

local socket = internet.connect(server, tonumber(port))

local ssh = {}

-- authenticate to the server
function ssh.auth(socket,user,pass)
    -- send auth request
    socket:write("SSH-2.0-PlotOS\r\n")
    -- send the user and password
    socket:write("\r\n")
    socket:write(user.."\r\n")
    socket:write(pass.."\r\n")
    -- get the response
    local response = socket:read(math.huge)
    -- check if the response is ok
    if response:find("SSH-2.0-PlotOS") then
        return true, response
    else
        return false
    end

end





local user, pass = io.read(), io.read()
local sc, res = ssh.auth(socket,user,pass)
print(res or "no response")