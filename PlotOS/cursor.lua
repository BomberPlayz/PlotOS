_G.cursor = {}
cursor.x = 1
cursor.y = 1

cursor.blink = true
local gpu = require("driver").load("gpu")

function cursor.set(x, y)
  local ox,oy = 0,0
  local proc = require("process")
  if proc.isProcess() then
    local p = proc.findByThread(coroutine.running())
    ox,oy = p.io.screen.offset.x,p.io.screen.offset.y
  else

  end
  cursor.x = x+ox
  cursor.y = y+oy
end

function cursor.get()
  return {x=cursor.x,y=cursor.y}
end

local w,h = gpu.getResolution()

function cursor.setBlink(blink)
  cursor.blink = blink
  local proc = require("process")
  if proc.isProcess() then
    local p = proc.findByThread(coroutine.running())
    w,h = p.io.screen.width, p.io.screen.height
  else
    w,h = gpu.getResolution()
  end

  if cursor.x > w then
    cursor.x = 1
    cursor.y = cursor.y + 1
  end
  if cursor.y > h then
    cursor.y = cursor.y - 1
  end

  -- if blink is true, set foreground to background, and vica versa. If blink is false, switch them back. Then make a dot at the cursor's position.
  local bg = gpu.getBackground()
  local fg = gpu.getForeground()
  local cc = {gpu.get(cursor.x, cursor.y)}
  if blink then 
    gpu.setBackground(fg)
    gpu.setForeground(bg)
    
    gpu.set(cursor.x, cursor.y, cc[1])
  else

    gpu.set(cursor.x, cursor.y, cc[1])
  end

  gpu.setForeground(fg)
  gpu.setBackground(bg)

end






