_G.cursor = {}
cursor.x = 1
cursor.y = 1
local gpu = component.gpu

function cursor.set(x, y)
  cursor.x = x
  cursor.y = y
end

function cursor.get()
  return {x=cursor.x,y=cursor.y}
end

function cursor.setBlink(blink)
  cursor.blink = blink
end

function cursor.setForegroundColor(color)
  cursor.fgcolor = color
end

function cursor.setBackgroundColor(color)
  cursor.bgColor = color
end

--[[
require("process").new("blinkingCursor",[[
  while true do
    if cursor.blink == true then
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
  end
]]--)