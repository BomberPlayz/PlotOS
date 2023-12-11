local gpu = require("driver").load("gpu")

local w,h = gpu.getResolution()

gpu.setForeground(0xffffff)
gpu.setBackground(0x000000)
gpu.fill(1, 1, w, h, " ")
prt_x = 1
prt_y = 1