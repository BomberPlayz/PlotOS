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
    local a,b,_,c,d = computer.pullSignal(0.5)

    if a == "key_down" then
      c = keyboard.keys[c]
      if c == "enter" then
        if pusy > 0 then
          cursor.x = cursor.x+1
        end
        cursor.setBlink(false)
        io.writeline("")
        cursor.x = prt_x
        cursor.y = prt_y
        return txt
      elseif c == "back" then
        if pusy > 0 then
          pusy = pusy-1
          txt = string.sub(txt,1,(string.len(txt)-1))
          component.gpu.fill(prt_x-1,prt_y,1,1, " ")
          prt_x = prt_x-1
          cursor.x = prt_x+1
          cursor.setBlink(false)
          cursor.x = prt_x
          cursor.setBlink(true)
          if txt == nil then txt = "" end
        end
      else

        if disabledCodeMap[c] == nil then
          if codeMap[c] ~= nil then c = codeMap[c] end
          if c ~= nil then
            txt = txt..c
            pusy = pusy+1
            cursor.x = prt_x+1
            cursor.y = prt_y
            cursor.setBlink(true)

            cursor.x = prt_x
            cursor.y = prt_y
            cursor.setBlink(false)
            io.write(c)
          end
        end
      end
    elseif a == nil then
      if cursor.blink then
        cursor.setBlink(false)
      else
        cursor.setBlink(true)
      end
    end

    end
end

function io.write(txt)
  component.gpu.set(prt_x,prt_y,txt)
  prt_x = prt_x+string.len(txt)
end

function io.writeline(txt)
  io.write(txt)
  local w,h = gpu.getResolution()
  if prt_y == h-1 then
    gpu.copy(1,1,w,h,0,-1)
    gpu.fill(1,h,w,1," ")
  else
    prt_y = prt_y + 1
  end
  prt_x = 1
end

_G.io = io