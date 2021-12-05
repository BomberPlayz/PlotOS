require("process").new("blinkingCursor",[[
  local cursor = require("/PlotOS/cursor")
  local gpu = require("component").gpu
  while true do
    local prevfg = gpu.getForeground()
      local prevbg = gpu.getBackground()

      local a,b,c,d,e,f,g = gpu.get(prt_x,prt_y)
      gpu.setForeground(cursor.fgcolor)
      gpu.setForeground(cursor.bgcolor)
      gpu.set(cursor.x,cursor.y,a)
      gpu.setForeground(prevfg)
      gpu.setForeground(prevbg)
      os.sleep(0.5)
  end
]])