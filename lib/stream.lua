--- Stream library for handling basic data streams.

--- @class Stream
--- @field public buffer string
--- @field public size number
--- @field public cursors table
--- @field public defaultCursor StreamCursor
--- @field public maxSize number
--- @field public realPos number Starting position of the buffer in absolute terms
local Stream = {}

--- @class StreamCursor
--- @field private stream Stream The parent stream
--- @field private position number The cursor's position (1-based)
--- @field private canRead boolean
--- @field private canWrite boolean
--- Cursor methods (for use with metatable)
local CursorMethods = {}
CursorMethods.__index = CursorMethods -- Set __index *before* defining methods

--- Read data from the stream using a cursor.
--- @param self StreamCursor The cursor to use for reading
--- @param n number Number of bytes to read
--- @return string|nil Data read from the stream, or nil if not readable
--- @return string|nil Error message if not readable
function CursorMethods:read(n)
    if not self.canRead then
        return nil, "Cursor cannot read"
    end
    
    if not n then
        n = self.stream.size - self.position + 1
    end

    -- Ensure we don't read beyond buffer bounds
    local toRead = math.min(n, self.stream.size - self.position + 1)
    if toRead <= 0 then return nil end
    
    local result = self.stream.buffer:sub(self.position, self.position + toRead - 1)
    self.position = self.position + toRead

    return result
end

--- Write data to the stream using a cursor.
--- @param self StreamCursor The cursor to use for writing
--- @param data string Data to write to the stream
--- @return number|nil Number of bytes written, or nil if not writable
--- @return string|nil Error message if not writable
function CursorMethods:write(data)
    if not self.canWrite then
        return nil, "Cursor cannot write"
    end

    -- Extend buffer if writing beyond current end
    if self.position > self.stream.size + 1 then
        self.stream.buffer = self.stream.buffer .. string.rep("\0", self.position - self.stream.size - 1)
    end

    local oldEnd = self.stream.size + 1
    local newBuffer = self.stream.buffer:sub(1, self.position - 1) .. data .. self.stream.buffer:sub(self.position)
    local newSize = #newBuffer

    -- Store write position for cursor updates
    local writePos = self.position
    local writeLen = #data

    -- First, record absolute positions
    for _, c in ipairs(self.stream.cursors) do
        c._absPos = (c.position - 1) + self.stream.realPos
    end

    -- Handle maxSize limit
    if newSize > self.stream.maxSize then
        local excess = newSize - self.stream.maxSize
        local trimPoint = excess + 1

        -- First update realPos before adjusting cursors
        local oldRealPos = self.stream.realPos
        self.stream.realPos = self.stream.realPos + excess
        
        -- Adjust all cursors before trimming
        for _, cursor in ipairs(self.stream.cursors) do
            if cursor.position < trimPoint then
                -- If cursor would be trimmed off, move to start
                cursor.position = 1
            else
                cursor.position = cursor.position - excess
            end
        end

        -- Update buffer
        self.stream.buffer = newBuffer:sub(trimPoint)
        
        -- Adjust write position after trim
        writePos = writePos - excess
        if writePos < 1 then writePos = 1 end
    else
        self.stream.buffer = newBuffer
    end

    self.stream.size = #self.stream.buffer

    -- Now restore positions from absolute positions
    for _, c in ipairs(self.stream.cursors) do
        local newRel = c._absPos - self.stream.realPos
        if newRel < 0 then newRel = 0 end
        if newRel > self.stream.size then
            newRel = self.stream.size
        end
        c.position = newRel + 1
        c._absPos = nil
    end

    -- Update our position
    self.position = writePos + writeLen

    return #data
end

--- Seek to a position in the stream using a cursor.
--- @param self StreamCursor The cursor to use for seeking
--- @param whence string Where to seek from: "set", "cur", or "end"
--- @param offset number Offset from the whence position
--- @return number|nil New position (0-based), or nil on error
--- @return string|nil Error message on failure
function CursorMethods:seek(whence, offset)
    whence = whence or "cur"
    offset = offset or 0

    local absolutePos
    if (whence == "set") then
        absolutePos = offset + 1
    elseif (whence == "cur") then
        absolutePos = (self.position - 1 + self.stream.realPos) + offset
    elseif (whence == "end") then
        absolutePos = (self.stream.size + self.stream.realPos) + offset
    else
        return nil, "Invalid whence"
    end

    -- Convert absolute position to buffer position
    local bufferPos = absolutePos - self.stream.realPos
    
    -- Clamp to valid range
    if (bufferPos < 1) then
        bufferPos = 1
        absolutePos = self.stream.realPos + 1
    elseif (bufferPos > self.stream.size + 1) then
        bufferPos = self.stream.size + 1
        absolutePos = self.stream.realPos + self.stream.size + 1
    end

    self.position = bufferPos
    return absolutePos - 1  -- Return 0-based absolute position
end

--- Close a cursor.
--- @param self StreamCursor The cursor to close
function CursorMethods:close()
    -- Remove the cursor from the stream's list
    for i, c in ipairs(self.stream.cursors) do
        if (c == self) then
            table.remove(self.stream.cursors, i)
            break
        end
    end

    if require then
        local p = require("process")
        if p.currentProcess then
            for i, h in ipairs(p.currentProcess.io.handles) do
                if (h == self) then
                    table.remove(p.currentProcess.io.handles, i)
                    break
                end
            end
        end
    end
end

--- Create a new cursor for reading or writing.
--- @param self Stream
--- @param canRead boolean Whether the cursor can read
--- @param canWrite boolean Whether the cursor can write
--- @return StreamCursor
function Stream:createCursor(canRead, canWrite)
    local cursor = {
        stream = self,
        position = 1,
        canRead = canRead,
        canWrite = canWrite
    }
    setmetatable(cursor, CursorMethods)
    table.insert(self.cursors, cursor)
    if require then
        local p = require("process")
        if p.currentProcess then
            table.insert(p.currentProcess.io.handles, cursor)
        end
    end
    return cursor
end

--- Read data from the stream (using the default cursor).
--- @param self Stream
--- @param n number Number of bytes to read
--- @return string|nil Data read from the stream, or nil if not readable
--- @return string|nil Error message if not readable
function Stream:read(n)
    return self.defaultCursor:read(n)
end

--- Write data to the stream (using the default cursor).
--- @param self Stream
--- @param data string Data to write to the stream
--- @return number|nil Number of bytes written, or nil if not writable
--- @return string|nil Error message if not writable
function Stream:write(data)
    return self.defaultCursor:write(data)
end

--- Seek to a position in the stream (using the default cursor).
--- @param self Stream
--- @param whence string Where to seek from: "set", "cur", or "end"
--- @param offset number Offset from the whence position
--- @return number|nil New position (0-based), or nil on error
--- @return string|nil Error message on failure
function Stream:seek(whence, offset)
    return self.defaultCursor:seek(whence, offset)
end

--- Close the stream (closes all cursors).
--- @param self Stream
function Stream:close()
    for _, cursor in ipairs(self.cursors) do
        cursor:close()
    end
    self.buffer = ""
    self.size = 0
end

Stream.__index = Stream -- Make Stream index itself
setmetatable(Stream, {
    __call = function(cls, ...)
        return cls.new(...)
    end
})

--- Create a new Stream instance.
--- @param options? {buffer: string, size: number, maxSize: number} Options for the stream
--- @return Stream
function Stream.new(options)
    options = options or {}
    local self = setmetatable({}, Stream) -- Fix: Use Stream as metatable directly
    self.buffer = options.buffer or ""
    self.size = options.size or #self.buffer
    self.maxSize = options.maxSize or math.huge
    self.realPos = 0
    self.cursors = {}
    
    self.defaultCursor = self:createCursor(true, true)
    
    return self
end

return Stream