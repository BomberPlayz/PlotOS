--- FakeStream library for simulating streams with callbacks.

--- @class FakeStream
--- @field private onRead function
--- @field private onWrite function
--- @field private onSeek function
--- @field private isCursorPosValid function
--- @field private size number
--- @field private cursors table
--- @field public defaultCursor FakeStreamCursor
--- @field private position number
local FakeStream = {}

--- @class FakeStreamCursor
--- @field private stream FakeStream
--- @field private position number
--- @field private canRead boolean
--- @field private canWrite boolean
local CursorMethods = {}
CursorMethods.__index = CursorMethods

function CursorMethods:read(n)
    if not self.canRead then
        return nil, "Cursor cannot read"
    end
    
    if self.stream.onRead then
        return self.stream.onRead(self.position, n)
    end
    return nil, "No read handler"
end

function CursorMethods:write(data)
    if not self.canWrite then
        return nil, "Cursor cannot write"
    end

    if self.stream.onWrite then
        local written = self.stream.onWrite(self.position, data)
        if written then
            self.position = self.position + #data
        end
        return written
    end
    return nil, "No write handler"
end

function CursorMethods:seek(whence, offset)
    whence = whence or "cur"
    offset = offset or 0

    local newPos
    if self.stream.onSeek then
        newPos = self.stream.onSeek(whence, offset, self.position)
        if not newPos then
            return nil, "Seek failed"
        end
    else
        -- Default seek behavior
        if whence == "set" then
            newPos = offset + 1
        elseif whence == "cur" then
            newPos = self.position + offset
        elseif whence == "end" then
            newPos = self.stream.size + offset + 1
        else
            return nil, "Invalid whence"
        end

        if self.stream.isCursorPosValid and not self.stream.isCursorPosValid(newPos) then
            return nil, "Invalid position"
        end
    end

    if newPos < 1 then newPos = 1 end
    self.position = newPos
    return newPos - 1 -- Convert to 0-based
end

function CursorMethods:close()
    for i, c in ipairs(self.stream.cursors) do
        if c == self then
            table.remove(self.stream.cursors, i)
            break
        end
    end
end

function FakeStream:createCursor(canRead, canWrite)
    local cursor = {
        stream = self,
        position = 1,
        canRead = canRead,
        canWrite = canWrite
    }
    setmetatable(cursor, CursorMethods)
    table.insert(self.cursors, cursor)
    return cursor
end

function FakeStream:read(n)
    return self.defaultCursor:read(n)
end

function FakeStream:write(data)
    return self.defaultCursor:write(data)
end

function FakeStream:seek(whence, offset)
    return self.defaultCursor:seek(whence, offset)
end

function FakeStream:close()
    for _, cursor in ipairs(self.cursors) do
        cursor:close()
    end
end

FakeStream.__index = FakeStream
setmetatable(FakeStream, {
    __call = function(cls, ...)
        return cls.new(...)
    end
})

--- Create a new FakeStream instance.
--- @param options {onRead: function, onWrite: function, onSeek: function, isCursorPosValid: function} Callback functions for stream operations
--- @return FakeStream
function FakeStream.new(options)
    options = options or {}
    local self = setmetatable({}, FakeStream)
    self.onRead = options.onRead
    self.onWrite = options.onWrite
    self.onSeek = options.onSeek
    self.isCursorPosValid = options.isCursorPosValid
    self.cursors = {}
    self.size = 0
    
    self.defaultCursor = self:createCursor(true, true)
    
    return self
end

return FakeStream
