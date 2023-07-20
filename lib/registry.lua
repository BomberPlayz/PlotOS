--MAJOR TODO: IMPLEMENT LOCKING
--MAJOR TODO: IMPLEMENT LOCKING
--MAJOR TODO: IMPLEMENT LOCKING

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

local fs = require("fs")
registryPath = fs.canonical(registryPath)

function split(inputstr, sep)
    sep = sep or "%s"
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
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
    end

    regdata = res
end

local function saveRegistry(categories)
    local toSave = {}
    if not categories then
        -- save all
    else
        -- save only specific categories
    end
end

readRegistry()

print(require("serialization").json.encode(regdata))

local registry = {}

registry.createCategory = function(name, permissionLevel)

end

registry.removeCategory = function(name)

end

registry.exists = function(path)
    path = parsePath(path)


end

registry.getType = function(path)

end

registry.set = function(path, value, type)

end

registry.get = function(path, default)

end

registry.types = types

error("end") --to make require not cache it

return registry