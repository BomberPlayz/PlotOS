local gpu = require("driver").load("gpu")

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local log4po = {}

--add a check if that type doesnt exist write the raw data
log4po.tableToTextComponentList = function(t)
  local textComponentList = {}

  table.insert(textComponentList, log4po.newTextComponent("{", 0x000000, 0xfffb2b))

  local i = 0
  for k,v in pairs(t) do
    i = i + 1
    if type(v) == "table" then
      if type(k) == "string" then
        table.insert(textComponentList, log4po.newTextComponent("[", 0x000000, 0x69ff0a))
        table.insert(textComponentList, log4po.newTextComponent([["]]..k..[["]], 0x000000, 0x008f0a))
        table.insert(textComponentList, log4po.newTextComponent("]", 0x000000, 0x69ff0a))
      else
        table.insert(textComponentList, log4po.newTextComponent("[", 0x000000, 0x69ff0a))
        table.insert(textComponentList, log4po.newTextComponent(k, 0x000000, 0xfab700))
        table.insert(textComponentList, log4po.newTextComponent("]", 0x000000, 0x69ff0a))
      end
      table.insert(textComponentList, log4po.newTextComponent(" = ", 0x000000, 0xffffff))
      for k2,v2 in ipairs(log4po.tableToTextComponentList(v)) do
        table.insert(textComponentList, v2)
      end
      if i < tablelength(t) then
        table.insert(textComponentList, log4po.newTextComponent(", ", 0x000000, 0xffffff))
      end
    elseif type(v) == "string" then
      if type(k) == "string" then
        table.insert(textComponentList, log4po.newTextComponent("[", 0x000000, 0x69ff0a))
        table.insert(textComponentList, log4po.newTextComponent([["]]..k..[["]], 0x000000, 0x008f0a))
        table.insert(textComponentList, log4po.newTextComponent("]", 0x000000, 0x69ff0a))
      else
        table.insert(textComponentList, log4po.newTextComponent("[", 0x000000, 0x69ff0a))
        table.insert(textComponentList, log4po.newTextComponent(k, 0x000000, 0xfab700))
        table.insert(textComponentList, log4po.newTextComponent("]", 0x000000, 0x69ff0a))
      end
      table.insert(textComponentList, log4po.newTextComponent(" = ", 0x000000, 0xffffff))
      table.insert(textComponentList, log4po.newTextComponent([["]]..v..[["]], 0x000000, 0x008f0a))
      if i < tablelength(t) then
        table.insert(textComponentList, log4po.newTextComponent(", ", 0x000000, 0xffffff))
      end
    elseif type(v) == "number" then
      if type(k) == "string" then
        table.insert(textComponentList, log4po.newTextComponent("[", 0x000000, 0x69ff0a))
        table.insert(textComponentList, log4po.newTextComponent([["]]..k..[["]], 0x000000, 0x008f0a))
        table.insert(textComponentList, log4po.newTextComponent("]", 0x000000, 0x69ff0a))
      else
        table.insert(textComponentList, log4po.newTextComponent("[", 0x000000, 0x69ff0a))
        table.insert(textComponentList, log4po.newTextComponent(k, 0x000000, 0xfab700))
        table.insert(textComponentList, log4po.newTextComponent("]", 0x000000, 0x69ff0a))
      end
      table.insert(textComponentList, log4po.newTextComponent(" = ", 0x000000, 0xffffff))
      table.insert(textComponentList, log4po.newTextComponent(tostring(v), 0x000000, 0xfab700))
      if i < tablelength(t) then
        table.insert(textComponentList, log4po.newTextComponent(", ", 0x000000, 0xffffff))
      end
    end
  end

  table.insert(textComponentList, log4po.newTextComponent("}", 0x000000, 0xfffb2b))
  return textComponentList
end

log4po.newTextComponent = function(text,bg,fg)
  local t = {}
  t.text = text
  t.bg = bg
  t.fg = fg
  return t
end

log4po.textComponentListToString = function(textComponentList)
  local str = ""
  for i,v in ipairs(textComponentList) do
    str = str..v.text
  end
  return str
end

log4po.textComponentLog = function(textComponent)
  local prevfg = gpu.getForeground()
  local prevbg = gpu.getBackground()

  if type(textComponent) == "table" then
    if type(textComponent[1]) == "table" then
      for k,v in pairs(textComponent) do
        if v["fg"] == nil then v["fg"] = 0xffffff end
        if v["bg"] == nil then v["bg"] = 0x000000 end
        gpu.setForeground(v["fg"])
        gpu.setBackground(v["bg"])
        io.write(tostring(v["text"]))
      end
    elseif tablelength(textComponent) > 0 then
      if textComponent["fg"] == nil then textComponent["fg"] = 0xffffff end
      if textComponent["bg"] == nil then textComponent["bg"] = 0x000000 end
      gpu.setForeground(textComponent["fg"])
      gpu.setBackground(textComponent["bg"])
      io.write(tostring(textComponent["text"]))
    else
      print("Invalid text component")
    end
  else
    print("Invalid text component")
  end

  gpu.setForeground(prevfg)
  gpu.setBackground(prevbg)
  print("")
end

log4po.log = function(...)
  local args = {...};
  local toPrint = "";
  local argTypes = {}

  for i,v in ipairs(args) do
    argTypes[i] = type(v)
  end

  if argTypes[1] == "string" then
    for i=1,#args do
      toPrint = toPrint .. tostring(args[i])
      if i < #args then
        toPrint = toPrint .. ",  " 
      end
    end
    print(toPrint)
  elseif argTypes[1] == "table" then
    for i=1,#args do
      local tc = log4po.tableToTextComponentList(args[i])
      log4po.textComponentLog(tc)
    end
  end
end

return log4po
