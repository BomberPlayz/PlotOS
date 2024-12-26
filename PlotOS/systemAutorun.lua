local process = require("process")

process.load("Shell", os.getEnv("SHELL"))
process.load("cursorblink","/bin/cursorblink.lua")
process.load("journald", "/bin/journald.lua")
--process.load("Rainmeter", "/bin/rainmeter.lua")
