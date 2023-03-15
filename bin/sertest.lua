local serialization = require("serialization")

local inpLua = {
    test="Hello, world!",
    test2=123,
    test3=true,
    test4={
        test5="Hello, world!",
        test6=123,
        test7=true,
    }
}

print("INI: \n"..serialization.ini.encode(inpLua))
print("LUA: \n"..serialization.lua.encode(inpLua))
print("YAML: \n"..serialization.yaml.encode(inpLua))