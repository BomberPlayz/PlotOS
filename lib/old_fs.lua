local api = {}

local function split (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end




api.mounts = _G.fsmounts

--api.mainFs = require("component").proxy(require("component").get("f6b"))
api.mainFs = rawFs

api.mount = function(fs, path, pointer)

  
  local lpath = path:sub(-1) == "/" and path:sub(1,-2) or path


  table.insert(api.mounts, {path=lpath,fs=fs,pointer=pointer or "/"})
end

api.link = function(srcpath, virtpath)


  local respath,fs = api.resolve(srcpath)
  table.insert(api.mounts, {path=respath, fs=fs, pointer=virtpath})

end

api.resolve = function(path, ignoreNon)
  if type(ignoreNon) == "nil" then ignoreNon = false end
  local splited = split(path, "/")
  local solvedpath = "/"
  local solvedfs = api.mainFs
  local fpath = "/"
  
  for k,v in ipairs(splited) do
    local skipSlash = false
    solvedpath = solvedpath..v
    fpath = fpath..v
    for k,v in ipairs(api.mounts) do
      
      if v.path == solvedpath then
        solvedfs = v.fs
        solvedpath = v.pointer
        skipSlash = true
      end
    end
   -- print(solvedpath.." in "..solvedfs.getLabel())

    if not skipSlash then
    if solvedfs.exists(solvedpath) and solvedfs.isDirectory(solvedpath) then solvedpath = solvedpath.."/" elseif not solvedfs.exists(solvedpath) and not ignoreNon then return nil else if type(api.mounts[k+1]) ~= "nil" then solvedpath = solvedpath.."/" end end
    end


 end
  return solvedpath,solvedfs
end

api.exists = function(path)
  local f = api.resolve(path)
  if not f then return false else return true end
end

api.open = function(file,mode)
  local ret = {}
  local solvedpath,solvedfs = api.resolve(file)
  local h,r = solvedfs.open(file,mode)
  if not h then return nil,r end
  ret.handle = h
  function ret:read(len) return solvedfs.read(self.handle, len) end
  function ret:write(data) return solvedfs.write(self.handle, data) end
  function ret:close() return solvedfs.close(self.handle) end
  return ret
end

api.isDirectory = function(path)
  local solvedpath, solvedfs = api.resolve(path)
  return solvedfs.isDirectory(solvedpath)
end

api.mkdir = function(path)
  local solvedpath, solvedfs = api.resolve(path, true)
  return solvedfs.makeDirectory(solvedpath)
end

api.size = function(path)
  local solvedpath, solvedfs = api.resolve(path)
  return solvedfs.size(solvedpath)
end

api.lastModified = function(path)
  local solvedpath,solvedfs = api.resolve(path)
  return solvedfs.lastModified(solvedpath)
end

api.rename = function(from, to)
  local solvedpath,solvedfs = api.resolve(from)
  local topath = api.resolve(to, true)
  return solvedfs.rename(solvedpath, topath)
end

api.remove = function(path)
  local solvedpath,solvedfs = api.resolve(path)
  return solvedfs.remove(solvedpath)
end

api.list = function(path)
  local solvedpath,solvedfs = api.resolve(path)
  local toret = solvedfs.list(solvedpath)

  for k,v in ipairs(api.mounts) do
    if api.basepath(v.path) == path then
      table.insert(toret, api.filename(v.path))
    end
  end
  return toret
end

api.normalize = function(path)
  local splited = split(path, "/")
  local rek = {}
  for k,v in ipairs(splited) do
    if v == ".." then table.remove(rek, #rek) else
      table.insert(rek, v)
    end
  end
  local ret = ""
  for k,v in ipairs(rek) do
    ret = ret.."/"..v
  end
  return ret
end

api.filename = function(path)
  local splited = split(path, "/")
  local ret = splited[#splited]



  return ret
end

api.basepath = function(path)
  local splited = split(path, "/")
  return type(splited[#splited-1]) ~= "nil" and splited[splited+1] or "/"
end

--local handle = api.open("/lib/filesystem.lua")
--print(handle:read(1024))
--handle:close()

return api