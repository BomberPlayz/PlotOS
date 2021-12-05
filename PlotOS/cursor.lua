_G.cursor = {}
cursor.x = 1
cursor.y = 1

cursor.blink = true
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



