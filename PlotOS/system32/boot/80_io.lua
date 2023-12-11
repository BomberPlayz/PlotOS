local io = {}
local keyboard = require("keyboard")
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

function io.read()
  local txt = ""
  local pusy = 0
  cursor.y = prt_y
  cursor.x = prt_x
  cursor.setBlink(true)
  while true do
    local a,b,bb,c,d = computer.pullSignal(0.5)
    local proc = require("process")
    if proc.isProcess() then
      local p = proc.findByThread(coroutine.running())
      w,h = p.io.screen.width, p.io.screen.height
    else
      w,h = gpu.getResolution()
    end
    local ox,oy = 0,0
    if proc.isProcess() then
      local p = proc.findByThread(coroutine.running())
      ox,oy = p.io.screen.offset.x,p.io.screen.offset.y
    else

    end

    if a == "key_down" then
      if bb == 13 then
        if pusy > 0 then
          cursor.x = cursor.x+1
        end
        cursor.x = prt_x
        cursor.setBlink(false)
        io.writeline("")
        cursor.x = prt_x
        cursor.y = prt_y
        return txt
      elseif bb == 8 then
        if pusy > 0 then
          pusy = pusy-1
          txt = string.sub(txt,1,(string.len(txt)-1))
          gpu.fill(prt_x-1,prt_y,1,1, " ")
          prt_x = prt_x-1
          cursor.x = prt_x+1
          cursor.setBlink(false)
          cursor.x = prt_x
          cursor.setBlink(true)

          if txt == nil then txt = "" end
        end
      elseif bb == 127 then --i dont think we supported del, even before

      elseif bb > 31 then
        txt = txt..string.char(bb)
        pusy = pusy+1
        cursor.x = prt_x+1
        cursor.y = prt_y
        cursor.setBlink(true)

        cursor.x = prt_x
        cursor.y = prt_y
        cursor.setBlink(false)

        io.write(string.char(bb))
        --cursor.x = prt_x+1
        cursor.x = prt_x
      end
    elseif bb == nil then
      if cursor.blink then
        cursor.setBlink(false)
      else
        cursor.setBlink(true)
      end
    end
  end
end

function io.write(txt)
  local proc = require("process")
  if proc.isProcess() then
    local p = proc.findByThread(coroutine.running())
    w,h = p.io.screen.width, p.io.screen.height
  else
    w,h = gpu.getResolution()
  end
  local ox,oy = 0,0
  if proc.isProcess() then
    local p = proc.findByThread(coroutine.running())
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

local function split(string,sep)
  string = tostring(string)
  sep = tostring(sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  string:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

function io.setScreenSize(w, h)
  local proc = require("process")
  if proc.isProcess() then
    local p = proc.findByThread(coroutine.running())
    p.io.screen.width = w
    p.io.screen.height = h
  end
end

function io.writeline(txt)
  local dat = split(txt, "\n")
  local proc = require("process")
  local w, h, ox, oy

  if proc.isProcess() then
    local p = proc.findByThread(coroutine.running())
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
    local p = proc.findByThread(coroutine.running())
    p.io.screen.width = w
    p.io.screen.height = h
  else

  end
end

_G.io = io
