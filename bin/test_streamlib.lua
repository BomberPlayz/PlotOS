local Stream = require("stream")

local function testCreate()
    local s = Stream.new()
    assert(s.size == 0, "New stream should be empty by default")
end

local function testWriteAndRead()
    local s = Stream.new()
    s:write("Hello")
    assert(s.size == 5, "Size should be 5 after writing 'Hello'")
    local readData = s:read(5)
    assert(readData == "Hello", "Read should return 'Hello'")
end

local function testSeek()
    local s = Stream.new({ buffer = "abcdef" })
    s:seek("set", 2)
    local readData = s:read(3)
    assert(readData == "cde", "Should read 'cde' after seeking to offset 2")
end

local function testMaxSizeTrim()
    local s = Stream.new({ maxSize = 10 })
    s:write("abcdefghij")
    assert(s.size == 10, "Should be at maxSize")
    s:write("XYZ")
    -- The buffer should be trimmed, new size still 10
    assert(s.size == 10, "Should remain at maxSize after writing more")
    s:seek("set", 0)
    local readData = s:read(10)
    assert(#readData == 10, "Buffer should remain 10 bytes")
end

local function testMultipleCursors()
    local s = Stream.new({ buffer = "1234567" })
    local c1 = s:createCursor(true, true)
    c1:seek("set", 3) -- point c1 to '4'
    local c2 = s:createCursor(true, true)
    c2:seek("set", 6) -- point c2 to '7'
    s:write("89")     -- default cursor appends
    assert(s.size == 9, "Size should be 9 after appending '89'")
    c1:write("X")
    assert(s.size == 10, "Should be 10 after writing 'X'")
    assert(c2:read(1) == "7", "c2 should still point to '7' before any shift")
end

local function runAll()
    print("Running Stream tests...")
    testCreate()
    testWriteAndRead()
    testSeek()
    testMaxSizeTrim()
    testMultipleCursors()
    print("All tests passed!")
end

runAll()
