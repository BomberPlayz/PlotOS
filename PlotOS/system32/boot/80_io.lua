local io = {}
local std = require("stdlib")
local gpu = require("driver").load("gpu")
local w,h = gpu.getResolution()



local codeMap = {
  space=" ",
  numpad0="0",
  numpad1="1",
  numpad2="2",
  numpad3="3",
  numpad4="4",
  numpad5="5",
  numpad6="6",
  numpad7="7",
  numpad8="8",
  numpad9="9",
  numpaddecimal=".",
  equals="=",
  apostrophe="'",
  grave="`"
}

local disabledCodeMap = {
  lshift=true,
  rshift=true,
  lcontrol=true,
  rcontrol=true,
  lmenu=true,
  rmenu=true,
  tab=true,
  numlock=true,
  scroll=true,
  pageUp=true,
  pageDown=true,
  insert=true,
  pause=true,
  f1=true,
  f2=true,
  f3=true,
  f4=true,
  f5=true,
  f6=true,
  f7=true,
  f8=true,
  f9=true,
  f10=true,
  f11=true,
  f12=true,
  f13=true,
  f14=true,
  f15=true,
  f16=true,
  f17=true,
  f18=true,
  f19=true,
  f20=true,
  f21=true,
  f22=true,
  f23=true,
  f24=true,
  up=true,
  down=true,
  left=true,
  right=true,
  home=true,
  ["end"]=true
}


-- CURSOR TERRITORY
io.cursor = {}
io.cursor.position = {1,1}
io.cursor.blink = false

function io.cursor.setPosition(x,y)
  local proc = require("process")

  local newposx, newposy = x, y

  if proc.isProcess() then -- if we are in a process, offset by the screen offset of that thing.
    local p = proc.currentProcess
    local offsetX, offsetY = p.io.screen.offset.x, p.io.screen.offset.y
    newposx, newposy = x+offsetX, y+offsetY
  end

  if io.cursor.blink then -- Pat, is this bad? if so please make better
    local oldx, oldy = io.cursor.position[1], io.cursor.position[2]
    io.cursor.position = {newposx,newposy}
    io.cursor.setBlink(true)
    io.cursor.position = {oldx,oldy}
    io.cursor.setBlink(false)
    io.cursor.position = {newposx,newposy}
  else
    io.cursor.position = {newposx, newposy}
  end
end

-- Pat, if you have any idea how to not have duplicate code here, fix it please
function io.cursor.addPosition(x,y)
  local proc = require("process")
  local newposx, newposy = x, y

  if proc.isProcess() then -- if we are in a process, offset by the screen offset of that thing.
    local p = proc.currentProcess
    local offsetX, offsetY = p.io.screen.offset.x, p.io.screen.offset.y
    newposx, newposy = x+offsetX, y+offsetY
  end

  if io.cursor.blink then -- Pat, is this bad? if so please make better
    local oldx, oldy = io.cursor.position[1], io.cursor.position[2]
    io.cursor.position = {newposx,newposy}
    io.cursor.setBlink(true)
    io.cursor.position = {oldx,oldy}
    io.cursor.setBlink(false)
    io.cursor.position = {newposx,newposy}
  else
    io.cursor.position = {newposx, newposy}
  end
end

function io.cursor.getPosition()
  return io.cursor.position
end

function io.cursor.setBlink(blink) --FIXME: not great!
  io.cursor.blink = blink
  local x,y = io.cursor.position[1],io.cursor.position[2]
  local bg = gpu.getBackground()
  local fg = gpu.getForeground()
  local cc = {gpu.get(x, y)}
  if blink then 
    gpu.setBackground(fg)
    gpu.setForeground(bg)
    gpu.set(x, y, cc[1])
  else
    gpu.set(x, y, cc[1])
  end
  gpu.setForeground(fg)
  gpu.setBackground(bg)
end

setmetatable(io.cursor, {
  __index = function(t,k)
    if k == "x" then
      return io.cursor.position[1]
    elseif k == "y" then
      return io.cursor.position[2]
    elseif k == "blink" then
      return io.cursor.blink
    end
  end,
  __newindex = function(t,k,v)
    if k == "x" then
      io.cursor.position[1] = v
    elseif k == "y" then
      io.cursor.position[2] = v
    elseif k == "blink" then
      io.cursor.setBlink(v)
    end
  end
}) -- TODO FOR PATRIIK: add more that are useful:tm:

-- END CURSOR TERRITORY

function io.read()
  local txt = ""
  local pusy = 0
  io.cursor.setPosition(prt_x,prt_y)
  io.cursor.setBlink(true)
  while true do
    local a,b,bb,c,d = computer.pullSignal(0.5)
    local proc = require("process")
    if proc.isProcess() then
      local p = proc.currentProcess
      w,h = p.io.screen.width, p.io.screen.height
    else
      w,h = gpu.getResolution()
    end
    local ox,oy = 0,0
    if proc.isProcess() then
      local p = proc.currentProcess
      ox,oy = p.io.screen.offset.x,p.io.screen.offset.y
    else

    end

    if a == "key_down" then
      if bb == 13 then
        if pusy > 0 then
          cursor.x = cursor.x+1
        end
        io.cursor.setBlink(true)
        io.writeline("")
        io.cursor.setPosition(prt_x,prt_y)
        return txt
      elseif bb == 8 then
        if pusy > 0 then
          pusy = pusy-1
          txt = string.sub(txt,1,(string.len(txt)-1))
          gpu.fill(prt_x-1,prt_y,1,1, " ")
          prt_x = prt_x-1
          --[[cursor.x = prt_x+1
          cursor.setBlink(false)
          cursor.x = prt_x
          cursor.setBlink(true)]]
          io.cursor.setPosition(prt_x,prt_y)
          io.cursor.setBlink(true)

          if txt == nil then txt = "" end
        end
      elseif bb == 127 then --i dont think we supported del, even before

      elseif bb > 31 then
        txt = txt..string.char(bb)
        pusy = pusy+1
        --[[
        cursor.x = prt_x+1
        cursor.y = prt_y
        IO.CURSOR.setBlink(true)

        cursor.x = prt_x
        cursor.y = prt_y
        cursor.setBlink(false)]]

        io.cursor.setPosition(prt_x+1,prt_y)
        io.cursor.setBlink(true)

        io.write(string.char(bb))
        --cursor.x = prt_x+1
        io.cursor.setPosition(prt_x, prt_y)
      end
    elseif bb == nil then
      if io.cursor.blink then
        io.cursor.setBlink(false)
      else
        io.cursor.setBlink(true)
      end
    end
  end
end

function io.write(txt)
  local proc = require("process")
  if proc.isProcess() then
    local p = proc.currentProcess
    w,h = p.io.screen.width, p.io.screen.height
  else
    w,h = gpu.getResolution()
  end
  local ox,oy = 0,0
  if proc.isProcess() then
    local p = proc.currentProcess
    ox,oy = p.io.screen.offset.x,p.io.screen.offset.y
  else

  end
  if prt_x > w then
    prt_x = 1
    prt_y = prt_y + 1
  end
  if prt_y > h then
    prt_y = prt_y - 1
    gpu.copy(1+ox,2+oy,w,h,0,-1)
    gpu.fill(1+ox,h+oy,w,1," ")
  end
  gpu.set(prt_x,prt_y,txt)
  prt_x = prt_x+string.len(txt)
end

function io.setScreenSize(w, h)
  local proc = require("process")
  if proc.isProcess() then
    local p = proc.currentProcess
    p.io.screen.width = w
    p.io.screen.height = h
  end
end

function io.writeline(txt)
  local dat = std.str.split(txt, "\n")
  local proc = require("process")
  local w, h, ox, oy

  if proc.isProcess() then
    local p = proc.currentProcess
    w, h = p.io.screen.width, p.io.screen.height
    ox, oy = p.io.screen.offset.x, p.io.screen.offset.y
  else
    w, h = gpu.getResolution()
  end

  for i = 1, #dat do
    io.write(dat[i])

    if prt_y == h - 1 then
      gpu.copy(1 + ox, 1 + oy, w, h, 0, -1)
      gpu.fill(1 + ox, h + oy, w, 1, " ")
    else
      prt_y = prt_y + 1
    end

    prt_x = 1
  end

  if #dat == 0 then
    if prt_y == h - 1 then
      gpu.copy(1 + ox, 1 + oy, w, h, 0, -1)
      gpu.fill(1 + ox, h + oy, w, 1, " ")
    else
      prt_y = prt_y + 1
    end

    prt_x = 1
  end
end

_G.io = io

function io.setScreenSize(w,h)
  local proc = require("process")
  if proc.isProcess() then
    local p = proc.currentProcess
    p.io.screen.width = w
    p.io.screen.height = h
  else
    -- we fuck right off
  end
end

function io.getScreenSize()
  local proc = require("process")
  if proc.isProcess() then
    local p = proc.currentProcess
    return p.io.screen.width, p.io.screen.height
  else
    return gpu.getResolution()
  end
end

_G.io = io
