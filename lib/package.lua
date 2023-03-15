local package = {}
local fs = rawFs
package.path = "/lib"
package.loaded = {}
function package.require(file)
  if not package.loaded[file] then
    local pac
    if fs.exists(package.path.."/"..file..".lua") then
      pac = raw_dofile(package.path.."/"..file..".lua")
    else
      if fs.exists(file..".lua") then
        pac = raw_dofile(file..".lua")
        else
        error("file "..file..".lua does not exist")
      end
    end


    package.loaded[file] = pac

  end

  return package.loaded[file]
end


function package.clear_cache()
  package.loaded = {
    component = component,
    computer = computer
  }
end
package.loaded.package = package
return package