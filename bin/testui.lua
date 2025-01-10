local gui = require("newgui")

local win = gui.window(10, 10, 45, 10)
win.title = "GUIIII"

local pb = gui.progressBar(1, 5, 45-2, 1, 100)
pb.color = 0x5a5a5a
pb.setProgress(-1)

win.addChild(pb)

gui.workspace.addChild(win)

while true do os.sleep(1) end