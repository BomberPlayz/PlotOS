--local driver = require("driver")

local filesystem = {}
local mtab = { name = "", children = {}, links = {} }
local fstab = {}

local function segments(path)
    local parts = {}
    for part in path:gmatch("[^\\/]+") do
        local current, up = part:find("^%.?%.$")
        if current then
            if up == 2 then
                table.remove(parts)
            end
        else
            table.insert(parts, part)
        end
    end
    return parts
end

local function findNode(path, create, resolve_links)
    checkArg(1, path, "string")
    local visited = {}
    local parts = segments(path)
    local ancestry = {}
    local node = mtab
    local index = 1
    while index <= #parts do
        local part = parts[index]
        ancestry[index] = node
        if not node.children[part] then
            local link_path = node.links[part]
            if link_path then
                if not resolve_links and #parts == index then break end

                if visited[path] then
                    return nil, string.format("link cycle detected '%s'", path)
                end
                -- the previous parts need to be conserved in case of future ../.. link cuts
                visited[path] = index
                local pst_path = "/" .. table.concat(parts, "/", index + 1)
                local pre_path

                if link_path:match("^[^/]") then
                    pre_path = table.concat(parts, "/", 1, index - 1) .. "/"
                    local link_parts = segments(link_path)
                    local join_parts = segments(pre_path .. link_path)
                    local back = (index - 1 + #link_parts) - #join_parts
                    index = index - back
                    node = ancestry[index]
                else
                    pre_path = ""
                    index = 1
                    node = mtab
                end

                path = pre_path .. link_path .. pst_path
                parts = segments(path)
                part = nil -- skip node movement
            elseif create then
                node.children[part] = { name = part, parent = node, children = {}, links = {} }
            else
                break
            end
        end
        if part then
            node = node.children[part]
            index = index + 1
        end
    end

    local vnode, vrest = node, #parts >= index and table.concat(parts, "/", index)
    local rest = vrest
    while node and not node.fs do
        rest = rest and filesystem.concat(node.name, rest) or node.name
        node = node.parent
    end
    return node, rest, vnode, vrest
end

-------------------------------------------------------------------------------

function filesystem.canonical(path)
    local result = table.concat(segments(path), "/")
    if unicode.sub(path, 1, 1) == "/" then
        return "/" .. result
    else
        return result
    end
end

function filesystem.concat(...)
    local set = table.pack(...)
    for index, value in ipairs(set) do
        checkArg(index, value, "string")
    end
    return filesystem.canonical(table.concat(set, "/"))
end

function filesystem.get(path)
    local node = findNode(path)
    if node.fs then
        local proxy = node.fs
        path = ""
        while node and node.parent do
            path = filesystem.concat(node.name, path)
            node = node.parent
        end
        path = filesystem.canonical(path)
        if path ~= "/" then
            path = "/" .. path
        end
        return proxy, path
    end
    return nil, "no such file system"
end

function filesystem.realPath(path)
    checkArg(1, path, "string")
    local node, rest = findNode(path, false, true)
    if not node then return nil, rest end
    local parts = { rest or nil }
    repeat
        table.insert(parts, 1, node.name)
        node = node.parent
    until not node
    return table.concat(parts, "/")
end

function filesystem.mount(fs, path)
    printk("Mounting " .. tostring(fs) .. " to " .. path)
    checkArg(1, fs, "string", "table")
    if type(fs) == "string" then
        fs = filesystem.proxy(fs)
    end
    assert(type(fs) == "table", "bad argument #1 (file system proxy or address expected)")
    checkArg(2, path, "string")

    local real
    if not mtab.fs then
        if path == "/" then
            real = path
        else
            return nil, "rootfs must be mounted first"
        end
    else
        local why
        real, why = filesystem.realPath(path)
        if not real then
            return nil, why
        end

        if filesystem.exists(real) and not filesystem.isDirectory(real) then
            return nil, "mount point is not a directory"
        end
    end

    local fsnode
    if fstab[real] then
        return nil, "another filesystem is already mounted here"
    end
    for _, node in pairs(fstab) do
        if node.fs.address == fs.address then
            fsnode = node
            break
        end
    end

    if not fsnode then
        fsnode = select(3, findNode(real, true))
        -- allow filesystems to intercept their own nodes
        fs.fsnode = fsnode
    else
        local pwd = filesystem.path(real)
        local parent = select(3, findNode(pwd, true))
        local name = filesystem.name(real)
        fsnode = setmetatable({ name = name, parent = parent }, { __index = fsnode })
        parent.children[name] = fsnode
    end

    fsnode.fs = fs
    fstab[real] = fsnode

    return true
end

function filesystem.path(path)
    local parts = segments(path)
    local result = table.concat(parts, "/", 1, #parts - 1) .. "/"
    if unicode.sub(path, 1, 1) == "/" and unicode.sub(result, 1, 1) ~= "/" then
        return "/" .. result
    else
        return result
    end
end

function filesystem.name(path)
    checkArg(1, path, "string")
    local parts = segments(path)
    return parts[#parts]
end

function filesystem.proxy(filter, options) -- only for compatilility
    checkArg(1, filter, "string")

    return component.proxy(filter)
end

function filesystem.exists(path)
    if not filesystem.realPath(filesystem.path(path)) then
        return false
    end
    local node, rest, vnode, vrest = findNode(path)
    if not vrest or vnode.links[vrest] then -- virtual directory or symbolic link
        return true
    elseif node and node.fs then
        return node.fs.exists(rest)
    end
    return false
end

function filesystem.isDirectory(path)
    local real, reason = filesystem.realPath(path)
    if not real then return nil, reason end
    local node, rest, vnode, vrest = findNode(real)
    if not vnode.fs and not vrest then
        return true -- virtual directory (mount point)
    end
    if node.fs then
        return not rest or node.fs.isDirectory(rest)
    end
    return false
end

function filesystem.list(path)
    local node, rest, vnode, vrest = findNode(path, false, true)
    local result = {}
    if node then
        result = node.fs and node.fs.list(rest or "") or {}
        -- `if not vrest` indicates that vnode reached the end of path
        -- in other words, vnode[children, links] represent path
        if not vrest then
            for k, n in pairs(vnode.children) do
                if not n.fs or fstab[filesystem.concat(path, k)] then
                    table.insert(result, k .. "/")
                end
            end
            for k in pairs(vnode.links) do
                table.insert(result, k)
            end
        end
    end
    local set = {}
    for _, name in ipairs(result) do
        set[filesystem.canonical(name)] = name
    end
    return function()
        local key, value = next(set)
        set[key or false] = nil
        return value
    end
end

local function readonly_wrap(proxy)
    checkArg(1, proxy, "table")
    if proxy.isReadOnly() then
        return proxy
    end

    local function roerr() return nil, "filesystem is readonly" end
    return setmetatable({
        rename = roerr,
        open = function(path, mode)
            checkArg(1, path, "string")
            checkArg(2, mode, "string")
            if mode:match("[wa]") then
                return roerr()
            end
            return proxy.open(path, mode)
        end,
        isReadOnly = function()
            return true
        end,
        write = roerr,
        setLabel = roerr,
        makeDirectory = roerr,
        remove = roerr,
    }, { __index = proxy })
end

local function bind_proxy(path)
    local real, reason = filesystem.realPath(path)
    if not real then
        return nil, reason
    end
    if not filesystem.isDirectory(real) then
        return nil, "must bind to a directory"
    end
    local real_fs, real_fs_path = filesystem.get(real)
    if real == real_fs_path then
        return real_fs
    end
    -- turn /tmp/foo into foo
    local rest = real:sub(#real_fs_path + 1)
    local function wrap_relative(fp)
        return function(mpath, ...)
            return fp(filesystem.concat(rest, mpath), ...)
        end
    end
    local bind = {
        type = "filesystem_bind",
        address = real,
        isReadOnly = real_fs.isReadOnly,
        list = wrap_relative(real_fs.list),
        isDirectory = wrap_relative(real_fs.isDirectory),
        size = wrap_relative(real_fs.size),
        lastModified = wrap_relative(real_fs.lastModified),
        exists = wrap_relative(real_fs.exists),
        open = wrap_relative(real_fs.open),
        remove = wrap_relative(real_fs.remove),
        read = real_fs.read,
        write = real_fs.write,
        close = real_fs.close,
        getLabel = function() return "" end,
        setLabel = function() return nil, "cannot set the label of a bind point" end,
    }
    return bind
end

filesystem.internal = {}
function filesystem.internal.proxy(filter, options)
    checkArg(1, filter, "string")
    checkArg(2, options, "table", "nil")
    options = options or {}
    local address, proxy, reason
    if options.bind then
        proxy, reason = bind_proxy(filter)
    else
        -- no options: filter should be a label or partial address
        for c in component.list("filesystem", true) do
            if component.invoke(c, "getLabel") == filter then
                address = c
                break
            end
            if c:sub(1, filter:len()) == filter then
                address = c
                break
            end
        end
        if not address then
            return nil, "no such file system"
        end
        proxy, reason = component.proxy(address)
    end
    if not proxy then
        return proxy, reason
    end
    if options.readonly then
        proxy = readonly_wrap(proxy)
    end
    return proxy
end

function filesystem.umount(fsOrPath)
    printk("Unmounting " .. tostring(fsOrPath))
    checkArg(1, fsOrPath, "string", "table")
    local real
    local fs
    local addr
    if type(fsOrPath) == "string" then
        real = filesystem.realPath(fsOrPath)
        addr = fsOrPath
    else -- table
        fs = fsOrPath
    end

    local paths = {}
    for path, node in pairs(filesystem.fstab) do
        if real == path or addr == node.fs.address or fs == node.fs then
            table.insert(paths, path)
        end
    end
    for _, path in ipairs(paths) do
        local node = filesystem.fstab[path]
        filesystem.fstab[path] = nil
        node.fs = nil
        node.parent.children[node.name] = nil
    end
    return #paths > 0
end

function filesystem.isLink(path)
    local name = filesystem.name(path)
    local node, rest, vnode, vrest = filesystem.findNode(filesystem.path(path), false, true)
    if not node then return nil, rest end
    local target = vnode.links[name]
    -- having vrest here indicates we are not at the
    -- owning vnode due to a mount point above this point
    -- but we can have a target when there is a link at
    -- the mount point root, with the same name
    if not vrest and target ~= nil then
        return true, target
    end
    return false
end

function filesystem.copy(fromPath, toPath)
    local data = false
    local input, reason = filesystem.open(fromPath, "rb")
    if input then
        local output = filesystem.open(toPath, "wb")
        if output then
            repeat
                data, reason = input:read(1024)
                if not data then break end
                data, reason = output:write(data)
                if not data then data, reason = false, "failed to write" end
            until not data
            output:close()
        end
        input:close()
    end
    return data == nil, reason
end

function filesystem.remove(path)
    local function removeVirtual()
        local _, _, vnode, vrest = filesystem.findNode(filesystem.path(path), false, true)
        -- vrest represents the remaining path beyond vnode
        -- vrest is nil if vnode reaches the full path
        -- thus, if vrest is NOT NIL, then we SHOULD NOT remove children nor links
        if not vrest then
            local name = filesystem.name(path)
            if vnode.children[name] or vnode.links[name] then
                vnode.children[name] = nil
                vnode.links[name] = nil
                while vnode and vnode.parent and not vnode.fs and not next(vnode.children) and not next(vnode.links) do
                    vnode.parent.children[vnode.name] = nil
                    vnode = vnode.parent
                end
                return true
            end
        end
        -- return false even if vrest is nil because this means it was a expected
        -- to be a real file
        return false
    end
    local function removePhysical()
        local node, rest = filesystem.findNode(path)
        if node.fs and rest then
            return node.fs.remove(rest)
        end
        return false
    end
    local success = removeVirtual()
    success = removePhysical() or success -- Always run.
    if success then
        return true
    else
        return nil, "no such file or directory"
    end
end

function filesystem.rename(oldPath, newPath)
    if filesystem.isLink(oldPath) then
        local _, _, vnode, _ = filesystem.findNode(filesystem.path(oldPath))
        local target = vnode.links[filesystem.name(oldPath)]
        local result, reason = filesystem.link(target, newPath)
        if result then
            filesystem.remove(oldPath)
        end
        return result, reason
    else
        local oldNode, oldRest = filesystem.findNode(oldPath)
        local newNode, newRest = filesystem.findNode(newPath)
        if oldNode.fs and oldRest and newNode.fs and newRest then
            if oldNode.fs.address == newNode.fs.address then
                return oldNode.fs.rename(oldRest, newRest)
            else
                local result, reason = filesystem.copy(oldPath, newPath)
                if result then
                    return filesystem.remove(oldPath)
                else
                    return nil, reason
                end
            end
        end
        return nil, "trying to read from or write to virtual directory"
    end
end

function filesystem.open(path, mode)
    printk("Opening file at " .. path .. " with mode " .. (mode or "r"))
    checkArg(1, path, "string")
    mode = tostring(mode or "r")
    checkArg(2, mode, "string")

    assert(({ r = true, rb = true, w = true, wb = true, a = true, ab = true })[mode],
        "bad argument #2 (r[b], w[b] or a[b] expected, got " .. mode .. ")")

    local node, rest = findNode(path, false, true)
    if not node then
        return nil, rest
    end
    if not node.fs or not rest or (({ r = true, rb = true })[mode] and not node.fs.exists(rest)) then
        return nil, "file not found"
    end

    local handle, reason = node.fs.open(rest, mode)
    if not handle then
        return nil, reason
    end

    return setmetatable({
        fs = node.fs,
        handle = handle,
    }, {
        __index = function(tbl, key)
            if not tbl.fs[key] then return end
            if not tbl.handle then
                return nil, "file is closed"
            end
            return function(self, ...)
                local h = self.handle
                if key == "close" then
                    self.handle = nil
                end
                return self.fs[key](h, ...)
            end
        end
    })
end

function filesystem.size(path)
    local node, rest = filesystem.findNode(path)
    if node.fs and rest then
        return node.fs.size(rest)
    end
    return nil, "no such file or directory"
end

function filesystem.makeDirectory(path)
    local node, rest = filesystem.findNode(path)
    if node.fs and rest then
        return node.fs.makeDirectory(rest)
    end
    return nil, "no such file or directory"
end

local labels = { "drivea", "drivec", "drived", "drivee", "drivef", "driveg", "driveh", "drivei", "drivej" }
local labelRif = {}
for k, v in ipairs(labels) do
    labelRif[v] = false
end

table.sort(labelRif)

function filesystem.getFreeLabel()
    local lab = ""
    for k, v in pairs(labelRif) do
        if labelRif[k] == false then
            return k
        end
    end
    return lab
end

function filesystem.reserveLabel(label)
    labelRif[label] = true
end

function filesystem.freeLabel(label)
    labelRif[label] = false
end

filesystem.findNode = findNode
filesystem.segments = segments
filesystem.fstab = fstab

-------------------------------------------------------------------------------

return filesystem
