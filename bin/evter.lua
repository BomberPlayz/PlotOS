while true do
    local a = { require("event").pull() }
    for i, v in ipairs(a) do
        io.write(v .. " ")
    end
    io.write("\n")
end
