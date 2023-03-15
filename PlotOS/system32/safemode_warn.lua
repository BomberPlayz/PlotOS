local process = require("process")
process.new("SafeMode", [[
local gpu = component.gpu
local process = require("process")
local w,h = gpu.getResolution()
while true do
    os.sleep(0.25)
    local bg = gpu.getBackground()
    local fg = gpu.getForeground()
    gpu.setForeground(0xffffff)
    gpu.setBackground(0x000000)
    local safemodetext = "Safe Mode"
    gpu.set(1,1,safemodetext)
    gpu.set(1,h,safemodetext)
    gpu.set(w-#safemodetext+1,1,safemodetext)
    gpu.set(w-#safemodetext+1,h,safemodetext)
    gpu.setBackground(bg)
    gpu.setForeground(fg)
end

]],"*")