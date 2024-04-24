local stream = require("stream")
local ramfs = {}
ramfs.files = {}
ramfs.openfiles = {}
--- Add a file to the ramfs, with custom code to run when the file is accessed.
--- @param file string The path to the file.
--- @param options {read: string, write: string}
function ramfs.addFile(file, options)
    ramfs.files[file] = options
end

function ramfs.getfakefs()
    local fakefs = {}
    function fakefs.spaceUsed()
        return 0
    end

    function fakefs.open(path, mode)
        if not path then return nil, "no path" end
        -- canonicalize path
        local path = fs.canonicalizePath(path)
        if mode == nil then mode = "r" end
        if mode == "r" then
            if ramfs.files[path] then
                table.insert(ramfs.openfiles, {
                    path = path,
                    mode = mode,
                    buffer = stream.create()
                })
            end
        end
        if mode == "w" then
            if ramfs.files[path] then
                table.insert(ramfs.openfiles, {
                    path = path,
                    mode = mode,
                    buffer = stream.create()
                })
            end
        end
        if mode == "a" then
            if ramfs.files[path] then
                table.insert(ramfs.openfiles, {
                    path = path,
                    mode = mode,
                    buffer = stream.create()
                })
            end
        end
        return #ramfs.openfiles
    end
end

return ramfs
