local reg = package.require("registry")
local ignore_greedy = reg.get("system/processes/force_respect")
local stream = {}

function stream.create(buf, greedy)
    if type(buf) == "boolean" then
        greedy = buf
        buf = nil
    end
    if not buf then
        buf = ""
    end
    if ignore_greedy then
        greedy = false
    end
    local ret = {}
    ret.buffer = buf
    ret.pos = 1
    ret.read = function(self, n)
        local actual_read = math.min(n, #self.buffer - self.pos + 1)
        local ret = self.buffer:sub(self.pos, self.pos + actual_read - 1)
        self.pos = self.pos + actual_read
        if not greedy and coroutine.running() then
            coroutine.yield()
        end
        return ret
    end
    ret.write = function(self, str)
        self.buffer = self.buffer .. str
        if not greedy and coroutine.running() then
            coroutine.yield()
        end
    end
    ret.seek = function(self, whence, offset)
        if whence == "set" then
            local actual_offset = math.min(offset, #self.buffer)
            self.pos = actual_offset
        elseif whence == "cur" then
            local actual_offset = math.min(self.pos+offset, #self.buffer)
            self.pos = actual_offset
        elseif whence == "end" then
            local actual_offset = math.min(#self.buffer+offset, #self.buffer)
            self.pos = actual_offset
        end
        return self.pos
    end
    ret.close = function(self)
        self = nil
    end
    return ret
end

--- A readonly stream with a defined size and loadData function, eg for reading from a file.
--- @param size number The size of the stream
--- @param loadData function The function to load data from the stream
--- @param cache? number Load data in front of the cursor by this much (default 256)
function stream.dynamicallyLoadedReadonly(size, loadData, cache)
    local ret = {}
    ret.size = size
    ret.pos = 1
    ret.loadData = loadData
    ret.cache = ""
    ret.cache_size = cache or 256
    ret.cache_pos = 1
    ret.cache_end = 0

    ret.read = function(self, n)
        local actual_read = math.min(n, self.size - self.pos + 1)
        -- fill the cache
        while self.cache_end - self.cache_pos < actual_read do
            if coroutine.running() then
                coroutine.yield()
            end
            local start = self.cache_pos
            local len = math.min(self.cache_size, self.size - start + 1)
            local data = self.loadData(start, len)
            self.cache = self.cache.. data
            self.cache_end = self.cache_end + #data
            -- cut the cache if it exceeds the cache limit
            if self.cache_end > self.cache_size then
                local excess = self.cache_end - self.cache_size
                self.cache = self.cache:sub(excess + 1)
                self.cache_pos = self.cache_pos - excess
                self.cache_end = self.cache_size
            end
        end
        -- cut the cache
        local ret = self.cache:sub(self.cache_pos, self.cache_pos + actual_read - 1)
        self.cache_pos = self.cache_pos + actual_read
        self.pos = self.pos + actual_read
        return ret
    end

    ret.seek = function(self, whence, offset)
        if whence == "set" then
            local actual_offset = math.min(offset, self.size)
            self.pos = actual_offset
            self.cache_pos = 1
            self.cache = ""
            self.cache_end = 0
        elseif whence == "cur" then
            local actual_offset = math.min(self.pos + offset, self.size)
            self.pos = actual_offset
            self.cache_pos = 1
            self.cache = ""
            self.cache_end = 0
        elseif whence == "end" then
            local actual_offset = math.min(self.size + offset, self.size)
            self.pos = actual_offset
            self.cache_pos = 1
            self.cache = ""
            self.cache_end = 0
        end
        return self.pos
    end

    ret.close = function(self)
        self = nil
    end

    ret.write = function(self, str)
        return nil, "Stream is readonly"
    end

    return ret
end

function stream.proxy(h)
    local ret = {}
    ret.read = function(self, n)
        return h.read(n)
    end
    ret.write = function(self, str)
        if type(str) == "number" then
            str = string.char(str)
        end
        h.write(str)
    end
    ret.seek = function(self, whence, offset)
        h.seek(whence, offset)
    end
    ret.close = function(self)
        h.close()
    end
    return ret
end

return stream
