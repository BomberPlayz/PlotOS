local tui = require("tui")

local n = tui.promptNumber("Enter a number", 42)
print("You entered: " .. n)

local s = tui.promptString("Enter a string", "Hello, world!")
print("You entered: " .. s)

local b = tui.promptBool("Enter a boolean", true)
print("You entered: " .. tostring(b))

print("Press any key to exit")
io.read()