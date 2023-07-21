local registryPath = "/PlotOS/system32/registry"

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
registryPath = fs.canonical(registryPath)
local lockPath = registryPath.."/locks"

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

local function split(inputstr, sep)
    sep = sep or "%s"
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function startsWith(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

local function parsePath(path)
    local keys = split(path,"/")
    local category = keys[1]
    if category then
        table.remove(keys,1)
    end
    return {category=category, path=keys}
end

local regdata

local function readByteAsNumber(h)
    local byte = h:read(1)
    if not byte then return nil end

    return byte:byte()
end

local function readBytes(h,count)
    local data = h:read(count)
    if not data then return nil end

    return data
end

--[[
local function readShort(h)
    local bytes = {}
    table.insert(bytes,h:read(1))
    table.insert(bytes,h:read(1))
    if h:read()
end
--]]

local function parseCollection(h,fileSize,length)
    if length == 0 then
        return {}
    end

    local res = {types.collection,{}}
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

            local name = readBytes(h,nameLength)
            totalRead = totalRead + nameLength

            if t == types.category then
                -- i think we can ignore it here
            elseif t == types.u8 then
                local b = readByteAsNumber(h)
                totalRead = totalRead + 1
                if not b then
                    error("Registry ended on incomplete key")
                end

                res[2][name] = {types.u8, b}
            elseif t == types.u16 then
                local b = readBytes(h,2)
                totalRead = totalRead + 2
                if not b then error("Registry ended on incomplete key") end

                res[2][name] = {types.u16, ({string.unpack("<I2", b)})[1]}
            elseif t == types.u32 then
                local b = readBytes(h,4)
                totalRead = totalRead + 4
                if not b then error("Registry ended on incomplete key") end

                res[2][name] = {types.u32, ({string.unpack("<I4", b)})[1]}
            elseif t == types.s8 then --this is very likely optimizable
                local b = readBytes(h,1)
                totalRead = totalRead + 1
                if not b then error("Registry ended on incomplete key") end

                res[2][name] = {types.u16, ({string.unpack("<b", b)})[1]}
            elseif t == types.s16 then
                local b = readBytes(h,2)
                totalRead = totalRead + 2
                if not b then error("Registry ended on incomplete key") end

                res[2][name] = {types.u16, ({string.unpack("<i2", b)})[1]}
            elseif t == types.s32 then
                local b = readBytes(h,4)
                totalRead = totalRead + 4
                if not b then error("Registry ended on incomplete key") end

                res[2][name] = {types.u32, ({string.unpack("<i4", b)})[1]}
            elseif t == types.shortString then
                local length = readByteAsNumber(h)
                totalRead = totalRead + 1
                if not length then error("Registry ended on incomplete key") end

                local d
                if length == 0 then d = "" else d = readBytes(h, length) end
                totalRead = totalRead + length
                res[2][name] = {types.shortString, d}
            elseif t == types.string then
                local length = readBytes(h,2)
                totalRead = totalRead + 2
                if not length then error("Registry ended on incomplete key") end
                length = string.unpack("<I2", length)

                local d
                if length == 0 then d = "" else d = readBytes(h, length) end
                totalRead = totalRead + length
                res[2][name] = {types.string, d}
            elseif t == types.longString then
                local length = readBytes(h,4)
                totalRead = totalRead + 4
                if not length then error("Registry ended on incomplete key") end
                length = string.unpack("<I4", length)

                local d
                if length == 0 then d = "" else d = readBytes(h, length) end
                totalRead = totalRead + length
                res[2][name] = {types.string, d}
            elseif t == types.collection then
                local length = readBytes(h,4)
                totalRead = totalRead + 4
                if not length then error("Registry ended on incomplete key") end
                length = string.unpack("<I4", length)
                totalRead = totalRead + length

                res[2][name] = parseCollection(h,fileSize,length)
            else
                error("Invalid registry type: "..t)
            end
        else
            break
        end

        t = nil
        nameLength = nil
    end

    return res
end


local function readRegistry()
    local categories,err = fs.list(registryPath)
    if err then error(categories) end

    local res = {}

    for category in categories do
        if not fs.isDirectory(registryPath.."/"..category) then
            while true do
                local locks,err = fs.list(lockPath)
                if err then error(locks) end

                local ok = true

                for lock in locks do
                    if startsWith(lock,category..".write") then
                        ok = false
                        break
                    end
                end
                if ok then break end
                sleep(0.25)
            end
            
            local lockName = category..".read."..string.format("%09d",math.random(0,999999999))

            local f = fs.open(lockPath.."/"..lockName,"w")
            f:close()

            res[category] = {types.category,{}}

            local rawH = fs.open(registryPath.."/"..category, "rb")
            local size = fs.size(registryPath.."/"..category)

            local h = {
                remainingData = size,
                cacheSize = nil,
                cache = nil,
                readToEnd = false,
                readBlockSize = 1024, --cache size, dont wanna rename it
                readMaxChunkSize = 2048,
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

            res[category] = parseCollection(h,size,size)

            rawH:close()
            fs.remove(lockPath.."/"..lockName)
        end
    end

    regdata = res
end

function saveRegistry()
    local categories,err = fs.list(registryPath)
    if err then error(categories) end

    for category, data in pairs(regdata) do
        if not fs.isDirectory(category) then
            while true do
                local locks,err = fs.list(lockPath)
                if err then error(locks) end

                local ok = true

                for lock in locks do
                    if startsWith(lock,category) then
                        ok = false
                        break
                    end
                end
                if ok then break end
                sleep(math.random(0.05,0.2))
            end
            
            local lockName = category..".write."..string.format("%09d",math.random(0,999999999))

            local f = fs.open(lockPath.."/"..lockName,"w")
            f:close()


            fs.remove(registryPath.."/"..category)
            local h = fs.open(registryPath.."/"..category, "wb")
            local s = h

            local function writeBytes(bytes)
                s:write(bytes)
            end

            local function writeByte(byte)
                s:write(string.char(byte))
            end

            local function writeString(str)
                writeBytes(string.pack("<I2", #str))
                s:write(str)
            end

            local function writeLongString(str)
                writeBytes(string.pack("<I4", #str))
                s:write(str)
            end

            --[[local function writeRegistryEntry(entry)
                local t = entry[1]
                local name = entry[2]

                writeByte(t)
                print(data)
                writeString(name)

                if t == types.u8 then
                    writeByte(data)
                elseif t == types.u16 then
                    writeBytes(string.pack("<I2", data))
                elseif t == types.u32 then
                    writeBytes(string.pack("<I4", data))
                elseif t == types.shortString then
                    writeByte(#data)
                    s.write(data)
                elseif t == types.string then
                    writeString(data)
                elseif t == types.longString then
                    writeLongString(data)
                elseif t == types.collection then
                    local datatowrite = ""
                    for k,v in pairs(data) do
                        datatowrite = datatowrite .. writeRegistryEntry(v)
                    end
                    writeBytes(string.pack("<I4", #datatowrite))
                    s:write(datatowrite)
                else
                    error("Invalid registry type: "..t)
                end
            end]]

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
                    for k,v in pairs(datar) do
                        datatowrite = datatowrite .. serializeEntry(v, k)
                    end
                    data = data .. string.pack("<I4", #datatowrite)
                    data = data .. datatowrite
                else
                    error("Invalid registry type: "..t)
                end

                return data
            end


            for k,v in pairs(data[2]) do
                s:write(serializeEntry(v, k))
            end

            s:close()

            fs.remove(lockPath.."/"..lockName)
        end
    end
end


kern_info("Loading registry...")
readRegistry()
kern_info(package.require("json").encode(regdata))
kern_info("Registry loaded!")




--example of the api:
-- registry.get("current_user/themes/selected")
-- registry.set("current_user/themes/selected", "dark")
-- registry.set("current_user/themes/selected", "dark", "shortString")
-- registry.exists("current_user/themes/selected")
-- registry.delete("current_user/themes/selected")

-- first element is the type, second is the data. the key is the name of the entry

local registry = {}
function split(str, sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)
    for each in str:gmatch(regex) do
        result[#result+1] = each
    end
    return result
end



function registry.set(path, value, type, noSave)
    local path = split(path, "/")
    local current = regdata
    local last = nil
    for i=1, #path-1 do



        if i==1 then
            if current[path[i]] then
                last = current
                current = current[path[i]]

            else
                current[path[i]] = {types.collection, {}}
                last = current
                current = current[path[i]]
            end
        else
            if current[2][path[i]] then
                last = current
                current = current[2][path[i]]

            else
                current[2][path[i]] = {types.collection, {}}
                last = current
                current = current[2][path[i]]
            end
        end
    end
    if type then
        current[2][path[#path]] = {type, value}
    else
        current[2][path[#path]] = {types.string, value}
    end
    if not noSave then
        saveRegistry()
    end
end

 
function registry.get(path)
    local origPath = path
    local parsed = parsePath(path)
    
    path = parsed.path
    local category = parsed.category

    if not regdata[category] then
        return nil
    end

    local current = regdata[category][2]
    for i,v in ipairs(path) do
        if not current[v] then
            return nil
        end
        if i ~= #path then
            if type(current[v][2]) ~= "table" then
                return nil
            end
            current = current[v][2]
        else
            return current[v][2], current[v][1]
        end
    end

    --[[
    local path = split(path, "/")
    local current = regdata
    for i=1, #path-1 do
        if i==1 then
            if current[path[i]A] then
                current = current[path[i]A]
            else
                if defaultValue then
                    registry.set(origPath, defaultValue, defaultType)
                    return defaultValue
                else
                    return nil
                end
            end
        else
            if not current[2] then
                if defaultValue then
                    registry.set(origPath, defaultValue, defaultType)
                    return defaultValue
                else
                    return nil
                end
            end
            if current[2][path[i]A] then
                current = current[2][path[i]A]
            else
                if defaultValue then
                    registry.set(origPath, defaultValue, defaultType)
                    return defaultValue
                else
                    return nil
                end
            end
        end
    end
    if current[2][path[#path]A] then
        return current[2][path[#path]A][2]
    else
        local compiled = ""
        for i=1, #path-1 do
            compiled = compiled .. path[i] .. "/"
        end
        
        if defaultValue then
            kern_info("Registry entry "..path[#path].." does not exist in path "..compiled..", creating")
            registry.set(origPath, defaultValue, defaultType)
            return defaultValue
        else
            kern_info("Registry entry "..path[#path].." does not exist in path "..compiled)
            return nil
        end
    end
    --]]
end

-- MIGHT NOT WORK
function registry.exists(path)
    local parsed = parsePath(path)
    local category = parsed.category
    local path = parsed.path

    if regdata[category] then
        local current = regdata[category]
        for i=1, #path-1 do
            if i==1 then
                if current[path[i]] then
                    current = current[path[i]]
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



function registry.save(categories)
    saveRegistry(categories)
end



registry.types = types

--TEMPORARY:
registry.readRegistry = readRegistry

return registry