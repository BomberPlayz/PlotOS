local gpu = require("driver").load("gpu")

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local log4po = {}

--- Returns a text component list with syntax highlighting and basic formatting of a lua table.
--- @param t table The table
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

--- Returns a text component with the data passed to the function.
--- @param data string The data
--- @param color number The background color
--- @param textColor number The text color
log4po.newTextComponent = function(text,bg,fg)
  local t = {}
  t.text = text
  t.bg = bg
  t.fg = fg
  return t
end

--- Returns a string from all of the text components in the text component list that was given to the function.
--- @param textComponentList table The text component list
log4po.textComponentListToString = function(textComponentList)
  local str = ""
  for i,v in ipairs(textComponentList) do
    str = str..v.text
  end
  return str
end

--- Logs out a list of text components.
--- @param textComponentList table The text component list
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
        --more bad code
        for a=1,string.len(tostring(textComponent["text"]))+1 do
          io.write(string.sub(tostring(textComponent["text"]), a,a))
        end 
      end
    elseif tablelength(textComponent) > 0 then
      if textComponent["fg"] == nil then textComponent["fg"] = 0xffffff end
      if textComponent["bg"] == nil then textComponent["bg"] = 0x000000 end
      gpu.setForeground(textComponent["fg"])
      gpu.setBackground(textComponent["bg"])
      --Bad code, but it works for now lol
      --io.write doesnt check if the string is longer then the screen width left. it only checks if the cursor isnt past the screen end and then it writes the string so im just gonna do this for now 
      --inefficiency 100
      
      for a=1,string.len(tostring(textComponent["text"]))+1 do
        io.write(string.sub(tostring(textComponent["text"]), a,a))
      end 
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
--- Logs out all objects that have been passed to it
--- @param ... any The objects to log
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
    log4po.textComponentLog(log4po.newTextComponent(toPrint, 0x000000, 0xffffff))
  elseif argTypes[1] == "table" then
    for i=1,#args do
      local tc = log4po.tableToTextComponentList(args[i])
      log4po.textComponentLog(tc)
    end
  end
end

--- Logs out all strings that were passed to it in red
--- @param ... any The strings to log
log4po.error = function(...)
  local args = {...};
  local toPrint = "";

  for i=1,#args do
    toPrint = toPrint .. tostring(args[i])
    if i < #args then
      toPrint = toPrint .. ",  " 
    end
  end
  log4po.textComponentLog(log4po.newTextComponent(toPrint, 0x000000, 0xff0000))
end

return log4po