local com = require("component")
local eln = com.ElnProbe
print("?probe min, 0%")
local min = io.read()
print("?probe max, 100%")
local max = io.read()
print("searching for voltage...")
print("type ~current voltage for input 1")
local inp1 = io.read()
print("type ~current voltage for input 2")
local inp2 = io.read()
