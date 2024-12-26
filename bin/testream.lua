local Stream = require("stream")

local stream = Stream.new({maxSize = 10})
local cursor1 = stream:createCursor(true, true)
local cursor2 = stream:createCursor(true, true)

cursor1:write("12345")
cursor2:seek("set", 0)
cursor1:write("67890")
cursor1:write("ABCDE") -- This should trigger trimming

print(cursor2:read(5))
print(cursor1:seek("set", 0))

assert(cursor2:read(5) == "67890") -- Should read from the new start
assert(cursor1:seek("set", 0) == 10) -- Should return absolute position