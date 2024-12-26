local path =  {...}
path = path[1]

local fs = require("filesystem")
local file = fs.open(path, "r")
if not file then
  error("file not found")
end

local Data = file:read("*a")
file:close()

local lines = {}
for line in Data:gmatch("[^\n]+") do
  table.insert(lines, line)
end

for i = 1, #lines do
  print(lines[i])
end
