local streamLib = require("stream")

local function assert_equal(expected, actual, message)
    if expected ~= actual then
        error(string.format("%s: expected %s, but got %s", message, tostring(expected), tostring(actual)))
    end
end

local function run_test(name, func)
    io.write("Running test: " .. name .. " ... ")
    local status, error = pcall(func)
    if status then
        print("PASSED")
    else
        print("FAILED")
        print(error)
    end
end

local tests = {
    -- Test 1: Create a new stream
    function()
        local stream = streamLib.new({})
        assert_equal(true, stream.canRead, "Default canRead value")
        assert_equal(true, stream.canWrite, "Default canWrite value")
        assert_equal(0, stream.size, "Initial stream size")
    end,

    -- Test 2: Create a stream with initial buffer
    function()
        local stream = streamLib.new({buffer = "Hello"})
        assert_equal(5, stream.size, "Stream size with initial buffer")
    end,

    -- Test 3: Write to stream
    function()
        local stream = streamLib.new({canWrite = true})
        local bytesWritten = stream:write("Hello, World!")
        assert_equal(13, bytesWritten, "Bytes written to stream")
        assert_equal(13, stream.size, "Stream size after write")
    end,

    -- Test 4: Read from stream
    function()
        local stream = streamLib.new({buffer = "Hello, World!", canRead = true})
        local content = stream:read(5)
        assert_equal("Hello", content, "Read first 5 characters")
        content = stream:read(8)
        assert_equal(", World!", content, "Read remaining characters")
    end,

    -- Test 5: Seek in stream
    function()
        local stream = streamLib.new({buffer = "Hello, World!", canRead = true})
        local position = stream:seek("set", 7)
        assert_equal(7, position, "Seek to position 7")
        local content = stream:read(5)
        assert_equal("World", content, "Read after seek")
    end,

    -- Test 6: Seek to end of stream
    function()
        local stream = streamLib.new({buffer = "Hello, World!", canRead = true})
        local position = stream:seek("end", -6)
        assert_equal(7, position, "Seek to 6 characters before end")
        local content = stream:read(6)
        assert_equal("World!", content, "Read last 6 characters")
    end,

    -- Test 7: Write and read from stream
    function()
        local stream = streamLib.new({canRead = true, canWrite = true})
        stream:write("Hello")
        stream:write(", ")
        stream:write("World!")
        stream:seek("set", 0)
        local content = stream:read(13)
        assert_equal("Hello, World!", content, "Read after multiple writes")
    end,

    -- Test 8: Read past end of stream
    function()
        local stream = streamLib.new({buffer = "Short", canRead = true})
        local content = stream:read(10)
        assert_equal("Short", content, "Read past end of stream")
    end,

    -- Test 9: Seek past end of stream
    function()
        local stream = streamLib.new({buffer = "Short", canRead = true, canWrite = true})
        local position = stream:seek("end", 5)
        assert_equal(10, position, "Seek past end of stream")
        stream:write("Append")
        assert_equal(16, stream.size, "Size after writing past end")
    end,

    -- Test 10: Read from non-readable stream
    function()
        local stream = streamLib.new({canRead = false})
        local content, err = stream:read(5)
        assert_equal(nil, content, "Content from non-readable stream")
        assert(err ~= nil, "Error message from non-readable stream")
    end,

    -- Test 11: Write to non-writable stream
    function()
        local stream = streamLib.new({canWrite = false})
        local written, err = stream:write("Test")
        assert_equal(nil, written, "Bytes written to non-writable stream")
        assert(err ~= nil, "Error message from non-writable stream")
    end,

    -- Test 12: Seek with different whence values
    function()
        local stream = streamLib.new({buffer = "1234567890", canRead = true})
        assert_equal(5, stream:seek("set", 6), "Seek set")
        assert_equal(7, stream:seek("cur", 2), "Seek cur")
        assert_equal(8, stream:seek("end", -1), "Seek end")
    end,

    -- Test 13: Invalid seek whence
    function()
        local stream = streamLib.new({canRead = true})
        local position, err = stream:seek("invalid", 0)
        assert_equal(nil, position, "Position after invalid seek")
        assert(err ~= nil, "Error message from invalid seek")
    end,

    -- Test 14: Write at different positions
    function()
        local stream = streamLib.new({buffer = "Hello, World!", canRead = true, canWrite = true})
        stream:seek("set", 7)
        stream:write("There")
        stream:seek("set", 0)
        local content = stream:read(20)
        assert_equal("Hello, There!", content, "Content after writing at position")
    end,

    -- Test 15: Close stream (no-op in this implementation)
    function()
        local stream = streamLib.new({})
        stream:close()
        assert_equal(true, stream.canRead, "Stream still readable after close")
        assert_equal(true, stream.canWrite, "Stream still writable after close")
    end,
}

print("Running Simplified Stream Library Test Suite")
print("============================================")

for i, test in ipairs(tests) do
    run_test(string.format("Test %d", i), test)
end

print("============================================")
print("Test Suite Completed")