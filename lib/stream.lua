--- Stream library for handling basic data streams.
-- @module stream

--- @class Stream
-- @field private buffer string
-- @field private size number
-- @field private cursors table
-- @field private defaultCursor StreamCursor
local Stream = {}

--- @class StreamCursor
-- @field private stream Stream The parent stream
-- @field private position number The cursor's position (1-based)
-- @field private canRead boolean
-- @field private canWrite boolean

--- Cursor methods (for use with metatable)
local CursorMethods = {}
CursorMethods.__index = CursorMethods -- Set __index *before* defining methods

--- Read data from the stream using a cursor.
-- @param self StreamCursor The cursor to use for reading
-- @param n number Number of bytes to read
-- @return string|nil Data read from the stream, or nil if not readable
-- @return string|nil Error message if not readable
function CursorMethods:read(n)
  if not self.canRead then
    return nil, "Cursor cannot read"
  end

  local toRead = math.min(n, self.stream.size - self.position + 1)
  local result = self.stream.buffer:sub(self.position, self.position + toRead - 1)
  self.position = self.position + toRead

  return result
end

--- Write data to the stream using a cursor.
-- @param self StreamCursor The cursor to use for writing
-- @param data string Data to write to the stream
-- @return number|nil Number of bytes written, or nil if not writable
-- @return string|nil Error message if not writable
function CursorMethods:write(data)
  if not self.canWrite then
    return nil, "Cursor cannot write"
  end

  self.stream.buffer = self.stream.buffer:sub(1, self.position - 1) .. data .. self.stream.buffer:sub(self.position)
  self.position = self.position + #data
  self.stream.size = math.max(self.stream.size, self.position - 1)

  -- Update positions of other cursors
  for _, otherCursor in ipairs(self.stream.cursors) do
    if otherCursor ~= self and otherCursor.position >= self.position - #data then
        otherCursor.position = otherCursor.position + #data
      end
  end

  return #data
end

--- Seek to a position in the stream using a cursor.
-- @param self StreamCursor The cursor to use for seeking
-- @param whence string Where to seek from: "set", "cur", or "end"
-- @param offset number Offset from the whence position
-- @return number|nil New position (0-based), or nil on error
-- @return string|nil Error message on failure
function CursorMethods:seek(whence, offset)
  whence = whence or "cur"
  offset = offset or 0

  local newPosition
  if whence == "set" then
    newPosition = offset + 1
  elseif whence == "cur" then
    newPosition = self.position + offset
  elseif whence == "end" then
    newPosition = self.stream.size + offset + 1
  else
    return nil, "Invalid whence"
  end

  if newPosition < 1 or newPosition > self.stream.size + 1 then
      return nil, "Position out of bounds"
  end

  self.position = newPosition
  return self.position - 1
end

--- Close a cursor.
-- @param self StreamCursor The cursor to close
function CursorMethods:close()
  -- Remove the cursor from the stream's list
  for i, c in ipairs(self.stream.cursors) do
    if c == self then
      table.remove(self.stream.cursors, i)
      break
    end
  end
end

--- Create a new cursor for reading or writing.
-- @param self Stream
-- @param canRead boolean Whether the cursor can read
-- @param canWrite boolean Whether the cursor can write
-- @return StreamCursor
function Stream:createCursor(canRead, canWrite)
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

--- Read data from the stream (using the default cursor).
-- @param self Stream
-- @param n number Number of bytes to read
-- @return string|nil Data read from the stream, or nil if not readable
-- @return string|nil Error message if not readable
function Stream:read(n)
  return self.defaultCursor:read(n)
end

--- Write data to the stream (using the default cursor).
-- @param self Stream
-- @param data string Data to write to the stream
-- @return number|nil Number of bytes written, or nil if not writable
-- @return string|nil Error message if not writable
function Stream:write(data)
  return self.defaultCursor:write(data)
end

--- Seek to a position in the stream (using the default cursor).
-- @param self Stream
-- @param whence string Where to seek from: "set", "cur", or "end"
-- @param offset number Offset from the whence position
-- @return number|nil New position (0-based), or nil on error
-- @return string|nil Error message on failure
function Stream:seek(whence, offset)
  return self.defaultCursor:seek(whence, offset)
end

--- Close the stream (closes all cursors).
-- @param self Stream
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
-- @param options table Configuration options for the stream
-- @return Stream
function Stream.new(options)
  options = options or {}
  local self = setmetatable({}, Stream) -- Fix: Use Stream as metatable directly
  self.buffer = options.buffer or ""
  self.size = options.size or #self.buffer
  self.cursors = {}
  
  self.defaultCursor = self:createCursor(true, true)
  
  return self
end

return Stream