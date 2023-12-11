while true do
    io.write("> ")
    local s = io.read() or ""
    if s == "exit" then break end
    local l, err = load(s, "=lua", nil, _ENV)
    if not l then
      print("ERR: "..err)
    else
        local ok, res = pcall(l)
        print((ok and "OK" or "ERR")..": "..tostring(res))
    end
end