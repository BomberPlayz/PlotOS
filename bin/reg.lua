local args = {...}

if not args[1] then
	print("Usage: reg <set|get|list|delete> <path> <value>")
	return
end

local reg = package.require("registry")

local function printTable(t)
	for k,v in pairs(t) do
		print(k.." = "..tostring(v))
	end
end

if args[1] == "set" then
	if not args[2] or not args[3] or not args[4] then
		print("Usage: reg set <path> <value> <type>")
		return
	end
	local path = args[2]
	local value = args[3]
	local type = args[4]


	reg.set(path, value, reg.types[type])
	print("Set "..path.." to "..value.." ("..type..")")
elseif args[1] == "get" then
	if not args[2] then
		print("Usage: reg get <path>")
		return
	end
	local path = args[2]
	local value = reg.get(path)
	if value then
		print(path.." = "..tostring(value))
	else
		print("No such path: "..path)
	end
elseif args[1] == "list" then
	if not args[2] then
		print("Usage: reg list <path>")
		return
	end
	local path = args[2]
	local value = reg.get(path)
	if value then
		printTable(value)
	else
		print("No such path: "..path)
	end
elseif args[1] == "delete" then
	if not args[2] then
		print("Usage: reg delete <path>")
		return
	end
	local path = args[2]
	local value = reg.get(path)
	if value then
		reg.delete(path)
		print("Deleted "..path)
	else
		print("No such path: "..path)
	end
else
	print("Usage: reg <set|get|list|delete> <path> <value>")


end