local registry = require("registry")
local fs = require("fs")
local process = require("process")

local libuser = {}

--- Get a user object
--- @param id string | number The user id or name
--- @return table | nil # The user table or nil if not found
function libuser.getUser(id)
    local user = registry.get()
end

--- Get the current user
--- @return table | nil # The user table or nil if not found
function libuser.getCurrentUser()
    return libuser.getUser(process.info().uid)
end

--- Create a user
--- @param options {name: string, password: string, home: string, permissions: table<string,string>}
function libuser.createUser(options)
    local user = {
        name = options.name,
        password = options.password,
        home = options.home,
        permissions = options.permissions
    }
    -- TODO: Create user
end

return libuser
