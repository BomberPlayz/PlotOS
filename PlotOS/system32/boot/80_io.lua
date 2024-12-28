local io = {}
local std = require("stdlib")
local gpu = require("driver").load("gpu")
local proc = require("process")
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

--- Read from the console.
--- @param options {history: table?, completionCallback: function?}? Options for the read function
--- @return string The string read from the console
function io.read(options)
  options = options or {}
  assert(type(options) == "table", "options must be a table or nil")
  assert(not options.history or type(options.history) == "table", "history must be a table or nil")
  assert(not options.completionCallback or type(options.completionCallback) == "function", "completionCallback must be a function or nil")

  local histcpy = {}
  local histIndex
  if options.history then
    for i = 1, #options.history do
      histcpy[i] = options.history[i]
    end
  end

  local readBuffer = ""
  local readBufferBak = ""
  local ucur = 1
  local offset = 1
  local cursor = io.cursor

  if cursor.y >= h then
    gpu.copy(1,2,w,h-1,0,-1)
    gpu.fill(1,1,w,1," ")
    cursor.y = cursor.y - 1
  end

  cursor.setBlink(true)

  local w, h

  local proc = require("process")
  if proc.isProcess() then
    local p = proc.currentProcess
    w, h = p.io.screen.width, p.io.screen.height
  else
    w, h = gpu.getResolution()
  end

  w = w - 1

  local beginX = cursor.x

  local function draw(offset)
    local s = readBuffer:sub(offset, offset + w - beginX)
    s = s .. string.rep(" ", w - beginX - #s)
    gpu.set(beginX,cursor.y,s)
    --io.write(s)
  end

  while true do
    local ev = {computer.pullSignal(0.5)}
    if ev[1] == "key_down" then
      local _, _, char, code = table.unpack(ev)
      
      if char == 13 then -- CR
        cursor.setBlink(false)
        draw(1)
        cursor.setPosition(1, cursor.y + 1)
        if cursor.y >= h then
          gpu.copy(1,2,w,h-1,0,-1)
          gpu.fill(1,1,w,1," ")
          cursor.y = cursor.y - 1
        end

        return readBuffer
      elseif char == 8 then -- Backspace
        if #readBuffer > 0 and ucur > 1 then
          readBuffer = readBuffer:sub(1, ucur-2) .. readBuffer:sub(ucur)
          if ucur-offset < 0 then offset = offset - 1 end
          ucur = ucur - 1
          cursor.setBlink(false)
          cursor.x = beginX+ucur-offset

          draw(offset)
          cursor.setBlink(true)
        end
      elseif char == 127 then -- Delete
        if #readBuffer > 0 and ucur <= #readBuffer then
          readBuffer = readBuffer:sub(1, ucur-1) .. readBuffer:sub(ucur+1)
          -- dont think we need to touch offset here?
          cursor.setBlink(false)
          cursor.x = beginX+ucur-offset

          draw(offset)
          cursor.setBlink(true)
        end
      elseif char == 9 then -- Tab
        if options.completionCallback then
          local ucurChar = readBuffer:sub(ucur, ucur)
          if ucurChar == " " or ucurChar == "" then
            local completion = options.completionCallback(readBuffer:sub(1, ucur-1))
            if completion and type("completion") == "string" then
              readBuffer = readBuffer:sub(1, ucur-1) .. completion .. readBuffer:sub(ucur)
              ucur = ucur + #completion
              offset = offset + math.max(0,(ucur-offset)-(w-beginX))
              cursor.setBlink(false)
              cursor.x = beginX+ucur-offset

              draw(offset)
              cursor.setBlink(true)
            end
          end
        end
      elseif code == 203 then -- left arrow
        if ucur > 1 then
          ucur = ucur - 1
          if ucur-offset < 0 then offset = offset - 1 end
          cursor.setBlink(false)
          cursor.x = beginX+ucur-offset

          draw(offset)
          cursor.setBlink(true)
        end
      elseif code == 205 then -- right arrow
        if ucur <= #readBuffer then
          ucur = ucur + 1
          if ucur-offset > w-beginX then offset = offset + 1 end
          cursor.setBlink(false)
          cursor.x = beginX+ucur-offset

          draw(offset)
          cursor.setBlink(true)
        end
      elseif code == 200 then -- up arrow
        if histIndex and histIndex > 1 then
          histcpy[histIndex] = readBuffer
          histIndex = histIndex - 1
          readBuffer = histcpy[histIndex]

          offset = math.max(1, #readBuffer-(w-beginX)+1)
          ucur = #readBuffer+1
          cursor.setBlink(false)
          cursor.x = beginX+ucur-offset

          draw(offset)
          cursor.setBlink(true)
        elseif not histIndex and #histcpy > 0 then
          histIndex = #histcpy
          readBufferBak = readBuffer
          readBuffer = histcpy[histIndex]

          offset = math.max(1, #readBuffer-(w-beginX)+1)
          ucur = #readBuffer+1
          cursor.setBlink(false)
          cursor.x = beginX+ucur-offset

          draw(offset)
          cursor.setBlink(true)
        end
      elseif code == 208 then -- down arrow
        if histIndex then
          if histIndex == #histcpy then
            histcpy[histIndex] = readBuffer
            readBuffer = readBufferBak
            histIndex = nil
          else
            histcpy[histIndex] = readBuffer
            histIndex = histIndex + 1
            readBuffer = histcpy[histIndex]
          end
          offset = math.max(1, #readBuffer-(w-beginX)+1)
          ucur = #readBuffer+1
          cursor.setBlink(false)
          cursor.x = beginX+ucur-offset

          draw(offset)
          cursor.setBlink(true)
        end
      elseif code == 199 then -- home
        offset = 1
        ucur = 1
        cursor.setBlink(false)
        cursor.x = beginX+ucur-offset

        draw(offset)
        cursor.setBlink(true)
      elseif code == 207 then -- end
        offset = math.max(1, #readBuffer-(w-beginX)+1)
        ucur = #readBuffer+1
        cursor.setBlink(false)
        cursor.x = beginX+ucur-offset

        draw(offset)
        cursor.setBlink(true)
      elseif char > 31 then -- printable character
        readBuffer = readBuffer:sub(1, ucur-1) .. string.char(char) .. readBuffer:sub(ucur)
        ucur = ucur + 1
        if ucur-offset > w-beginX then offset = offset + 1 end
        cursor.setBlink(false)
        cursor.x = beginX+ucur-offset

        draw(offset)
        cursor.setBlink(true)
      end
    elseif ev[1] == "clipboard" then
      readBuffer = readBuffer:sub(1, ucur-1) .. ev[3] .. readBuffer:sub(ucur)
      ucur = ucur + #ev[3]
      offset = offset + math.max(0,(ucur-offset)-(w-beginX))
      cursor.setBlink(false)
      cursor.x = beginX+ucur-offset

      draw(offset)
      cursor.setBlink(true)
    elseif ev[1] == nil then
      if cursor.blink then
        cursor.setBlink(false)
      else
        cursor.setBlink(true)
      end
    end
  end
end

local function write(txt)
  local w,h
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
  end

  while true do
    local chunkSize = w - io.cursor.x
    local chunk = txt:sub(1, chunkSize)    
    txt = txt:sub(chunkSize+1)
    
    gpu.set(io.cursor.x, io.cursor.y, chunk)
    
    io.cursor.setPosition(io.cursor.x + #chunk, io.cursor.y)
    if io.cursor.x == w then
      io.cursor.setPosition(1, io.cursor.y + 1)
    end
    if io.cursor.y == h then
      gpu.copy(1+ox,2+oy,w,h,0,-1)
      gpu.fill(1+ox,h+oy,w,1," ")
      io.cursor.y = io.cursor.y - 1
    end

    if txt == "" then break end
  end
end

local function splitNewlines(str)
  local res = {}
  local x = ""
  for i=1, #str do
    local char = str:sub(i,i)
    if char ~= "\n" then
      x = x .. char
    else
      if #x > 0 then
        table.insert(res, x)
        x = ""
      end
      table.insert(res, "\n")
    end
  end

  if #x > 0 then
    table.insert(res, x)
  end

  return res
end

--- Write to the console.
--- @param str string The string to write
function io.write(str)
  local ox,oy = 0,0
  if proc.isProcess() then
    local p = proc.currentProcess
    ox,oy = p.io.screen.offset.x,p.io.screen.offset.y
  end

  for _,v in ipairs(splitNewlines(str)) do
    if v == "\n" then
      io.cursor.y = io.cursor.y + 1
      io.cursor.x = 1
      if io.cursor.y == h then
        gpu.copy(1+ox,2+oy,w,h,0,-1)
        gpu.fill(1+ox,h+oy,w,1," ")
        io.cursor.y = io.cursor.y - 1
      end 
    else
      write(v)
    end
  end
end


function io.setScreenSize(w, h)
  local proc = require("process")
  if proc.isProcess() then
    local p = proc.currentProcess
    p.io.screen.width = w
    p.io.screen.height = h
  end
end


function io.writeline(str)
  io.write(str.."\n")
end

_G.io = io

function io.setScreenSize(w,h)
  local proc = require("process")
  if proc.isProcess() then
    local p = proc.currentProcess
    p.io.screen.width = w
    p.io.screen.height = h
  else
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
