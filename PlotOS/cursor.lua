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


