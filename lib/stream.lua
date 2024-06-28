--- Stream library for handling basic data streams.
-- @module stream

--- @class Stream
-- @field private buffer string
-- @field private position number
-- @field private size number
-- @field private canRead boolean
-- @field private canWrite boolean
local Stream = {}
Stream.__index = Stream

--- Create a new Stream instance.
-- @param options table Configuration options for the stream
-- @return Stream
function Stream.new(options)
    local self = setmetatable({}, Stream)
    self.buffer = options.buffer or ""
    self.position = 1
    self.size = options.size or #self.buffer
    self.canRead = options.canRead ~= false
    self.canWrite = options.canWrite ~= false
    return self
end

--- Read data from the stream.
-- @param n number Number of bytes to read
-- @return string|nil Data read from the stream, or nil if not readable
-- @return string|nil Error message if not readable
function Stream:read(n)
    if not self.canRead then
        return nil, "Stream is not readable"
    end

    local toRead = math.min(n, self.size - self.position + 1)
    local result = self.buffer:sub(self.position, self.position + toRead - 1)
    self.position = self.position + toRead

    return result
end

--- Write data to the stream.
-- @param data string Data to write to the stream
-- @return number|nil Number of bytes written, or nil if not writable
-- @return string|nil Error message if not writable
function Stream:write(data)
    if not self.canWrite then
        return nil, "Stream is not writable"
    end

    self.buffer = self.buffer:sub(1, self.position - 1) .. data .. self.buffer:sub(self.position + #data)
    self.position = self.position + #data
    self.size = math.max(self.size, self.position - 1)

    return #data
end

--- Seek to a position in the stream.
-- @param whence string Where to seek from: "set", "cur", or "end"
-- @param offset number Offset from the whence position
-- @return number|nil New position (0-based), or nil on error
-- @return string|nil Error message on failure
function Stream:seek(whence, offset)
    whence = whence or "cur"
    offset = offset or 0

    local newPosition
    if whence == "set" then
        newPosition = offset + 1
    elseif whence == "cur" then
        newPosition = self.position + offset
    elseif whence == "end" then
        newPosition = self.size + offset + 1
    else
        return nil, "Invalid whence"
    end

    newPosition = math.max(1, math.min(newPosition, self.size + 1))

    self.position = newPosition
    return self.position - 1
end

--- Close the stream.
function Stream:close()
    -- In this simple implementation, we don't need to do anything
    -- This method is included for API completeness
end

return Stream