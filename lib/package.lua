local package = {}
local fs = rawFs
local booted = false
package.path = "/lib"
package.loaded = {}
package.state = {}
local function load_file(path, file)
  if not fs.exists(path) then
    return nil
  end
  
  package.state[file] = 1
  local loader = booted and dofile or raw_dofile
  local result = loader(path)
  package.state[file] = 2
  
  return result
end

function package.require(file)
  -- Return cached module if already loaded
  if package.loaded[file] then
    return package.loaded[file]
  end

  -- Check for circular dependencies
  if package.state[file] == 1 then
    error("circular require detected")
  end

  -- Initialize state
  package.state[file] = 0

  -- Try to load from package path first, then current directory
  local paths = {
    package.path.."/"..file..".lua",
    file..".lua"
  }

  local pac
  for _, path in ipairs(paths) do
    pac = load_file(path, file)
    if pac then
      break
    end
  end

  if not pac then
    package.state[file] = 0
    error("file "..file..".lua does not exist")
  end

  package.loaded[file] = pac
  return pac
end


function package.clear_cache()
  package.loaded = {
    component = component,
    computer = computer
  }
end

function package.on_booted()
  fs = require("fs")
  booted = true
end

package.loaded.package = package
return package