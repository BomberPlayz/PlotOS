local bsod = {}
local component = require("component")
local computer = require("computer")
local gpu = component.gpu -- get primary gpu component
local w, h = gpu.getResolution()
function bsod(text)
gpu.fill(1, 1, w, h, " ") -- clears the screen
gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x0000FF)
gpu.fill(1, 1, w, h, " ")
gpu.set(w / 2 - #text / 2, h / 2 - 3, "Sorry, but a fatal error has occured!")
gpu.set(w / 2 - #text / 2, h / 2, text)

while true do os.sleep(0.5) computer.beep(1000, 0.5) end
end
return bsod