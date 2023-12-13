local std = require("stdlib")

local lock = {
    __locks = {},
}

local function canonicalizePath(path)
    local t = std.str.split(path, "/")
    return table.concat(t, "/")
end

lock.isLocked = function(path)
    path = canonicalizePath(path)
    local l = lock.__locks[path]

    if l == nil then return false end

    local write = false
    for i, v in ipairs(l) do
        if v ~= nil and v == true then
            write = true
            break
        end
    end

    return true, write
end

lock.lock = function(path, isWrite)
    path = canonicalizePath(path)
    local isLocked, lockedIsWrite = lock.isLocked(path)

    if isLocked and (lockedIsWrite or isWrite) then
        return false
    end

    lock.__locks[path] = lock.__locks[path] or {}
    for i,v in ipairs(lock.__locks[path]) do
        if v == nil then
            lock.__locks[path][i] = isWrite
            return true, i
        end
    end

    local len = #(lock.__locks[path])
    lock.__locks[path][len+1] = isWrite

    return true, len+1
end

lock.lockBlocking = function(path, type, retryInterval)
    while true do
        local r, id = lock.lock(path, type)
        if r then return true, id end
        os.sleep(retryInterval or 0.5)
    end
end

lock.unlock = function(path, id)
    path = canonicalizePath(path)
    if lock.__locks[path] ~= nil and #(lock.__locks[path]) <= id then
        table.remove(lock.__locks[path], id)
        if #lock.__locks[path] == 0 then
            lock.__locks[path] = nil
        end 
        return true
    end
    return false
end

return lock