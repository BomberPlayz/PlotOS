local process = require("process")

process.load("Shell", os.getEnv("SHELL"))
process.load("journald", "/bin/journald.lua")
process.load("mountd", "/bin/mountd.lua")
