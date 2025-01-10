local stream = package.require("stream")
local fs = package.require("fs")

local RamFS = {}
RamFS.__index = RamFS

function RamFS.new()
    local self = setmetatable({}, RamFS)
    self.files = {}
    self.openfiles = {}
    return self
end

--- Add a file to the ramfs, with custom code to run when the file is accessed.
--- @param file string The path to the file.
--- @param options {read: string, write: string}
function RamFS:addFile(file, options)
    local fullPath = fs.canonical(file)
    -- split the path into directories
    local directories = {}
    for dir in string.gmatch(fullPath, "[^/]+") do
        table.insert(directories, dir)
    end
    -- create the directories
    for i = 1, #directories do
        local dir = directories[i]
        if not self.files[dir] then
            self.files[dir] = {}
        end
    end
    self.files[file] = options
end

function RamFS:getfakefs()
    local fakefs = {}
    local self = self -- capture self for use in closure

    function fakefs.spaceUsed()
        return 0
    end

    function fakefs.open(path, mode)
        if not path then return nil, "no path" end
        -- canonicalize path
        local path = fs.canonical(path)
        if mode == nil then mode = "r" end
        --[[
        if self.files[path] and (mode == "r" or mode == "w" or mode == "a") then
            table.insert(self.openfiles, {
                path = path,
                mode = mode,
                buffer = self.files[path].buffer or stream.new(self.files[path].data or "")
            })
            return #self.openfiles
        end
        ]]
        local splitPath = {}
        for dir in string.gmatch(path, "[^/]+") do
            table.insert(splitPath, dir)
        end
        local dir = self.files
        for i = 1, #splitPath do
            if dir[splitPath[i]] then
                dir = dir[splitPath[i]]
            else
                return nil, "file not found"
            end
        end
        if mode == "r" or mode == "w" or mode == "a" then
            table.insert(self.openfiles, {
                path = path,
                mode = mode,
                buffer = dir.buffer or stream.new(dir.data or "")
            })
            return #self.openfiles
        end
        return nil, "file not found"
    end

    function fakefs.seek(handle, whence, offset)
        if not self.openfiles[handle] then return nil, "no file" end
        local file = self.openfiles[handle]
        return file.buffer:seek(whence, offset)
    end

    function fakefs.read(handle, n)
        if not self.openfiles[handle] then return nil, "no file" end
        local file = self.openfiles[handle]
        return file.buffer:read(n)
    end

    function fakefs.write(handle, data)
        if not self.openfiles[handle] then return nil, "no file" end
        local file = self.openfiles[handle]
        return file.buffer:write(data)
    end

    function fakefs.close(handle)
        if not self.openfiles[handle] then return nil, "no file" end
        table.remove(self.openfiles, handle)
    end

    function fakefs.list(path)
        printk("Listing files in", path)
        local files = {}
        -- split the path into directories
        local directories = {}
        for dir in string.gmatch(path, "[^/]+") do
            table.insert(directories, dir)
        end
        -- get the files in the directory
        local dir = self.files
        for i = 1, #directories do
            if dir[directories[i]] then
                dir = dir[directories[i]]
            else
                return nil, "directory not found"
            end
        end
        local ret = {}
        for file, _ in pairs(dir) do
            table.insert(ret, file)
        end
        return ret
    end

    function fakefs.exists(path)
        local path = fs.canonical(path)
        local splitPath = {}
        for dir in string.gmatch(path, "[^/]+") do
            table.insert(splitPath, dir)
        end
        local dir = self.files
        for i = 1, #splitPath do
            if dir[splitPath[i]] then
                dir = dir[splitPath[i]]
            else
                return false
            end
        end
        return true
    end

    return fakefs
end

return RamFS
