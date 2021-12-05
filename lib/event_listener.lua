local args = {...}

while true do
    local e,a,b,c,d,ff,f,g = require("event").pull(args[1])
   -- print("eeee "..tostring(args[1]))
    if not args[2] then error("No callback!") end

    args[2](e,a,b,c,d,ff,f,g)

end