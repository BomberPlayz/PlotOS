local registryPath = "/PlotOS/system32/registry"

---@class RegistryTypes
---@field category number Category type (0)
---@field s8 number Signed 8-bit integer type (1)
---@field u8 number Unsigned 8-bit integer type (2)
---@field s16 number Signed 16-bit integer type (3)
---@field u16 number Unsigned 16-bit integer type (4)
---@field s32 number Signed 32-bit integer type (5)
---@field u32 number Unsigned 32-bit integer type (6)
---@field shortString number Short string type (8)
---@field string number String type (9)
---@field longString number Long string type (10)
---@field collection number Collection type (255)
local types = {
    category = 0,
    s8 = 1,
    u8 = 2,
    s16 = 3,
    u16 = 4,
    s32 = 5,
    u32 = 6,
    --double = 7,
    shortString = 8,
    string = 9,
    longString = 10,

    collection = 255
}

local fs = package.require("fs")
local std = package.require("stdlib")
registryPath = fs.canonical(registryPath)
local lockPath = registryPath .. "/locks"

if not fs.exists(registryPath) or not fs.isDirectory(registryPath) then
    fs.makeDirectory(registryPath)
end

if not fs.exists(lockPath) or not fs.isDirectory(lockPath) then
    fs.makeDirectory(lockPath)
end

local function sleep(timeout)
    local deadline = computer.uptime() + (timeout or 0)
    repeat
        computer.pullSignal(deadline - computer.uptime())
    until computer.uptime() >= deadline
end

local function parsePath(path)
    local keys = std.str.split(path, "/")
    local category = keys[1]
    if category then
        table.remove(keys, 1)
    end
    return { category = category, path = keys }
end

local regdata = {}
local regmounts = {}
local reglocks = {}

local function lock(file, mode)
    if not file then error("missing file") end
    if not (mode == "r" or mode == "w") then error("mode invalid, expected r or w") end

    file = fs.canonical(file)

    printk("Registry: trying to lock "..file.." "..mode, "debug")
    if reglocks[file] then
        if mode == "r" then
            while true do
                local hasWriteLock = false
                for _,v in pairs(reglocks[file][2]) do
                    if v == 119 then hasWriteLock = true; break end
                end

                if not hasWriteLock then break end
                sleep(0.25)
            end
        elseif mode == "w" then
            while true do
                if #reglocks[file][2] == 0 then break end
                sleep(0.25) -- i know this sucks and can be done better
            end
        end
    else
        reglocks[file] = { 0, {} }
    end

    printk("Registry: locking "..file.." "..mode, "debug")
    local id = reglocks[file][1]
    reglocks[file][2][id] = mode:byte()
    reglocks[file][1] = id + 1

    return id
end

local function unlock(file, id)
    if not file then error("missing file") end
    if not id then error("missing id") end
    
    file = fs.canonical(file)

    if not reglocks[file] then
        return false
    end
    if not reglocks[file][2][id] then
        return false
    end

    reglocks[file][2][id] = nil

    return true
end

setmetatable(regdata, {
    __newindex = function() end,
    __index = function(t, k)
        return regmounts[k] and regmounts[k][2] or nil
    end,
    __pairs = function(t)
        return next, regmounts, nil
    end,
    __ipairs = function(t)
        local function iter(t, i)
            i = i + 1
            local v = regmounts[i]
            if v then
                return i, v[2]
            end
        end
        return iter, regmounts, 0
    end
})

local function readByteAsNumber(h)
    local byte = h:read(1)
    if not byte then return nil end

    return byte:byte()
end

local function readBytes(h, count)
    local data = h:read(count)
    if not data then return nil end

    return data
end

local function parseCollection(h, fileSize, length)
    if length == 0 then
        return { types.collection, {} }
    end

    local res = { types.collection, {} }
    
    local totalRead = 0
    while totalRead < length do
        local t = readByteAsNumber(h)
        totalRead = totalRead + 1
        local nameLength = readByteAsNumber(h)
        totalRead = totalRead + 1

        if t then
            if not nameLength then
                error("Registry ended on incomplete key")
            end

            local name = readBytes(h, nameLength)
            totalRead = totalRead + nameLength

            if t == types.category then -- FIXME: we dont save the categories with a type!!
                -- i think we can ignore it here
            elseif t == types.u8 then
                local b = readByteAsNumber(h)
                totalRead = totalRead + 1
                if not b then
                    error("Registry ended on incomplete key")
                end

                res[2][name] = { types.u8, b }
            elseif t == types.u16 then
                local b = readBytes(h, 2)
                totalRead = totalRead + 2
                if not b then error("Registry ended on incomplete key") end

                res[2][name] = { types.u16, ({ string.unpack("<I2", b) })[1] }
            elseif t == types.u32 then
                local b = readBytes(h, 4)
                totalRead = totalRead + 4
                if not b then error("Registry ended on incomplete key") end

                res[2][name] = { types.u32, ({ string.unpack("<I4", b) })[1] }
            elseif t == types.s8 then --this is very likely optimizable
                local b = readBytes(h, 1)
                totalRead = totalRead + 1
                if not b then error("Registry ended on incomplete key") end

                res[2][name] = { types.s8, ({ string.unpack("<b", b) })[1] }
            elseif t == types.s16 then
                local b = readBytes(h, 2)
                totalRead = totalRead + 2
                if not b then error("Registry ended on incomplete key") end

                res[2][name] = { types.s16, ({ string.unpack("<i2", b) })[1] }
            elseif t == types.s32 then
                local b = readBytes(h, 4)
                totalRead = totalRead + 4
                if not b then error("Registry ended on incomplete key") end

                res[2][name] = { types.s32, ({ string.unpack("<i4", b) })[1] }
            elseif t == types.shortString then
                local length = readByteAsNumber(h)
                totalRead = totalRead + 1
                if not length then error("Registry ended on incomplete key") end

                local d
                if length == 0 then d = "" else d = readBytes(h, length) end
                totalRead = totalRead + length
                res[2][name] = { types.shortString, d }
            elseif t == types.string then
                local length = readBytes(h, 2)
                totalRead = totalRead + 2
                if not length then error("Registry ended on incomplete key") end
                length = string.unpack("<I2", length)

                local d
                if length == 0 then d = "" else d = readBytes(h, length) end
                totalRead = totalRead + length
                res[2][name] = { types.string, d }
            elseif t == types.longString then
                local length = readBytes(h, 4)
                totalRead = totalRead + 4
                if not length then error("Registry ended on incomplete key") end
                length = string.unpack("<I4", length)

                local d
                if length == 0 then d = "" else d = readBytes(h, length) end
                totalRead = totalRead + length
                res[2][name] = { types.string, d }
            elseif t == types.collection then
                local length = readBytes(h, 4)
                totalRead = totalRead + 4
                if not length then error("Registry ended on incomplete key") end
                length = string.unpack("<I4", length)
                totalRead = totalRead + length

                res[2][name] = parseCollection(h, fileSize, length)
            else
                error("Invalid registry type: " .. t)
            end
        else
            break
        end

        t = nil
        nameLength = nil
    end

    return res
end

---@class Registry
---@field useTmpFilesToSave boolean Whether to use temporary files when saving registry data
local registry = {}
registry.useTmpFilesToSave = true

local function readRegistryFile(file)
    if not fs.exists(file) then return false, "File doesn't exist" end

    local id = lock(file, "r")
    printk("Registry: reading "..file)

    local rawH = fs.open(file, "rb")
    local size = fs.size(file)

    local h = {
        remainingData = size,
        cacheSize = nil,
        cache = nil,
        readToEnd = false,
        readBlockSize = _G.LOW_MEM and 256 or 1024, --cache size, dont wanna rename it
        readMaxChunkSize = _G.LOW_MEM and 512 or 2048,
        read = function(self, amount) --specifying amount that overflows the file will return nil
            if not self.cache then
                local availableBytes = self.readBlockSize

                if availableBytes > size then
                    availableBytes = size
                    self.remainingData = 0
                end

                self.cacheSize = availableBytes
                self.remainingData = size-availableBytes
                self.cache = rawH:read(availableBytes,"rb")
            end

            if self.remainingData == 0 and #self.cache == 0 then return nil end

            if #self.cache >= amount then
                local dat = string.sub(self.cache,1,amount)
                self.cache = string.sub(self.cache,amount+1)
                return dat
            end

            if #self.cache+self.remainingData >= amount then
                local totalRead = #self.cache
                local dat = self.cache
                self.cache = ""
                while amount-totalRead > 0 do
                    local toRead = math.max(math.min(self.readMaxChunkSize,amount-totalRead),math.min(self.remainingData,self.readBlockSize))
                    local data = rawH:read(toRead,"rb")
                    self.remainingData = self.remainingData - toRead

                    totalRead = totalRead + toRead
                    local overflow = totalRead-amount
                    if overflow > 0 then
                        self.cache = string.sub(data, #data-overflow+1)
                        data = string.sub(data,1,#data-#self.cache)
                    end
                    dat = dat .. data
                    data = nil
                    overflow = nil
                    toRead = nil
                end
                return dat
            end

            return nil
        end
    }

    local d = parseCollection(h,size,size)

    rawH:close()
    unlock(file, id)

    return d
end

local function mountRaw(file, name)
    if regmounts[name] then return false, "Something is already mounted at the specified name" end
    if not fs.exists(file) then return false, "File doesn't exist" end
    
    printk("Registry: Mounted "..file.." to "..name)
    regmounts[name] = {file, readRegistryFile(file)}
end

---Mounts a registry file to a specific name
---@param file string Path to the registry file
---@param name string Mount name
---@param createIfNotExists boolean Whether to create the file if it doesn't exist
---@return boolean success Whether the mount was successful
---@return boolean|string error Error message if mount failed
---@return boolean created Whether the file was created
function registry.mount(file, name, createIfNotExists)
    local created = false
    if regmounts[name] then return false, "Something is already mounted at the specified name" end
    if not fs.exists(file) then
        if createIfNotExists then
            local h = fs.open(file, "w")
            h:close()
            created = true
        else
            return false, "File doesn't exist"
        end
    end
    local path = fs.path(file)
    
    local bakFile = nil
    for fname in fs.list(path) do
        if not fs.isDirectory(fname) and std.str.startswith(fname, fs.name(file)..".old") then
            if bakFile then
                return false, "Multiple backup files present"
            else
                bakFile = fs.concat(path, fname)
            end
        end
    end

    if bakFile then
        fs.remove(file)

        fs.rename(bakFile, file)
    end

    return true, mountRaw(file, name), created
end

---Unmounts a registry mount
---@param name string Name of the mount to unmount
---@return boolean success Whether the unmount was successful
function registry.unmount(name)
    if regmounts[name] then
        registry.save(name)
        regmounts[name] = nil
        return true
    else
        return false
    end
end

---Saves a registry mount to disk
---@param name string Name of the mount to save
---@return boolean|nil success Whether the save was successful
---@return string|nil error Error message if save failed
function registry.save(name)
    local mount = regmounts[name]
    if not mount then return false, "Attempt to save nonexistent mount" end
    local path = mount[1]
    local data = mount[2][2]
    printk("Registry: saving "..name.." to "..path)
    if not fs.exists(path) then printk("Registry: "..path.." no longer exists, saving anyways", "warn") end
    if fs.isDirectory(path) then printk("Registry: "..path.." got turned into a directory, what the fuck", "error"); return false, "Save path is a directory" end

    local lockId = lock(path, "w")

    local h
    if registry.useTmpFilesToSave then
        fs.remove(path .. ".tmp")
        h = fs.open(path .. ".tmp", "wb")
    else
        fs.remove(path)
        h = fs.open(path, "wb")
    end
    local s = h

    local function serializeEntry(entry, name)
        local t = entry[1]
        local datar = entry[2]

        local data = ""
        data = data .. string.char(t)
        data = data .. string.char(#name)
        data = data .. name

        if t == types.u8 then
            data = data .. string.char(datar)
        elseif t == types.u16 then
            data = data .. string.pack("<I2", datar)
        elseif t == types.u32 then
            data = data .. string.pack("<I4", datar)
        elseif t == types.s8 then
            data = data .. string.pack("<i1", datar) --probably optimizable, doesnt matter
        elseif t == types.s16 then
            data = data .. string.pack("<i2", datar)
        elseif t == types.s32 then
            data = data .. string.pack("<i4", datar)
        elseif t == types.shortString then
            data = data .. string.char(#datar)
            data = data .. datar
        elseif t == types.string then
            data = data .. string.pack("<I2", #datar)
            data = data .. datar
        elseif t == types.longString then
            data = data .. string.pack("<I4", #datar)
            data = data .. datar
        elseif t == types.collection then
            local datatowrite = ""
            for k, v in pairs(datar) do
                datatowrite = datatowrite .. serializeEntry(v, k)
            end
            data = data .. string.pack("<I4", #datatowrite)
            data = data .. datatowrite
        else
            error("Invalid registry type: " .. t)
        end

        return data
    end


    for k, v in pairs(data) do
        s:write(serializeEntry(v, k))
    end

    s:close()

    if registry.useTmpFilesToSave then
        fs.remove(path)
        fs.rename(path .. ".tmp", path)
    end

    unlock(path, lockId)
end

--[[
local function readRegistry()
    local categories,err = fs.list(registryPath)
    if err then error(categories) end

    for category in categories do
        if not fs.isDirectory(registryPath.."/"..category) and std.str.endswith(category, ".reg") then
            local name = category:sub(1, #category-4)
            local ok, err = registry.mount(registryPath.."/"..category, name)
            if not ok then printk("Failed to load system registry at "..category..": "..(err or "unknown error"), "error") end
        end
    end
end
--]]

---Global function to save all mounted registry files
---@return nil
function saveFullRegistry()
    for k,v in pairs(regmounts) do
        registry.save(k)
    end
end

--printk("Loading registry...")
--readRegistry()
--printk("Registry data: "..package.require("json").encode(regdata), "debug")
--printk("Registry data: DISABLED FOR MEMORY OPTIMIZATION", "debug")
--printk("Registry loaded!")

---Sets a value in the registry
---@param path string Full path to the registry key (category/path/to/key)
---@param value any Value to set
---@param dataType? number Type from registry.types to use (defaults to string)
---@param noSave? boolean Whether to skip saving changes to disk
---@return boolean success Whether the set was successful
---@return string|nil error Error message if set failed
function registry.set(path, value, dataType, noSave)
    printk(
        "registry.set(\"" ..
        table.concat({ tostring(path), tostring(value), tostring(dataType), tostring(noSave) }, ", ") .. "\") called",
        "debug")
    local parsed = parsePath(path)
    local path = parsed.path
    local category = parsed.category
    local current = regdata[category]

    if not current then
        printk("Registry: nothing is mounted at /" .. tostring(category), "warn")
        return false, "path_not_mounted"
    end

    current = regdata[category][2]

    for i=1,#path-1 do
        local pathv = path[i]
        if current[pathv] then
            if current[pathv][1] == types.collection then
                current = current[pathv][2]
            else
                printk("Invalid path, encountered non collection on position "..i, "warn")
                return false, "non_collection_in_path"
            end
        else
            current[pathv] = { types.collection, {} }
            current = current[pathv][2]
        end
    end

    if dataType then
        current[path[#path]] = { dataType, value }
    else
        current[path[#path]] = { types.string, tostring(value) }
    end
    if not noSave then
        registry.save(category)
    end

    return true
end

local function registry_get_table_parser(tbl)
    local res = {}

    for k, v in pairs(tbl) do
        if type(v) == "table" then
            res[k] = registry_get_table_parser(v[2])
        else
            res[k] = v[2]
        end
    end

    return res
end

---Gets a value from the registry
---@param path string Full path to the registry key (category/path/to/key)
---@return any value The value at the specified path
---@return number|nil type The type of the value from registry.types
---@return string|nil error Error message if get failed
function registry.get(path) -- TODO: add type filter
    printk("registry.get(\"" .. table.concat({ tostring(path), tostring(getType) }, ", ") .. "\") called", "debug")
    local parsed = parsePath(path)
    local path = parsed.path
    local category = parsed.category
    local current = regdata[category]

    if not current then
        printk("Registry: nothing is mounted at /" .. tostring(category), "error")
        error("Nothing is mounted at /"..tostring(category))
    end

    current = regdata[category][2]

    for i=1,#path-1 do
        local pathv = path[i]
        if current[pathv] then
            if current[pathv][1] == types.collection then
                current = current[pathv][2]
            else
                printk("Invalid path, encountered non collection on position "..i, "warn")
                return nil, "non_collection_in_path"
            end
        else
            return nil, "parent_collection_not_found"
        end
    end

    local target = current[path[#path]]
    if target then
        return target[2], target[1]
    end
    return nil, "not_found"
end

---Checks if a path exists in the registry
---@param path string Full path to check (category/path/to/key)
---@return boolean exists Whether the path exists
function registry.exists(path)
    local parsed = parsePath(path)
    local category = parsed.category
    local path = parsed.path

    if regdata[category] then
        local current = regdata[category]
        for i = 1, #path - 1 do
            if i == 1 then
                if current[2][path[i]] then
                    current = current[2][path[i]]
                else
                    return false
                end
            else
                if not current[2] then
                    return false
                end
                if current[2][path[i]] then
                    current = current[2][path[i]]
                else
                    return false
                end
            end
        end
        return true
    else
        return false
    end
end

---Lists all entries at a specific path
---@param path string Full path to list (category/path/to)
---@return table<string,number>|false entries Table of entry name to type pairs, or false if path doesn't exist
function registry.list(path)
    local parsed = parsePath(path)
    local category = parsed.category
    local path = parsed.path

    if regdata[category] then
        local current = regdata[category]
        for i = 1, #path do
            if i == 1 then
                if current[2][path[i]] then
                    current = current[2][path[i]]
                else
                    return false
                end
            else
                if not current[2] then
                    return false
                end
                if current[2][path[i]] then
                    current = current[2][path[i]]
                else
                    return false
                end
            end
        end

        if current[1] ~= 255 then return false end

        local ret = {}
        for k, v in pairs(current[2]) do
            ret[k] = v[1]
        end
        return ret
    else
        return false
    end
end

registry.types = types

--TEMPORARY:
registry.readRegistry = readRegistry

return registry