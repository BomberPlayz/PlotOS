 local raw_loadfile = ...

_G.OSNAME = "PlotOS"
_G.OSVERSION = "0.0.3"
_G.OSRELEASE = "alpha"
 _G.OSSTATUS = 0
 _G.OS_LOGGING_START_TIME = math.floor(computer.uptime()*1000)/1000
 _G.OS_LOGGING_MAX_NUM_WIDTH = 0

 local component_invoke = component.invoke

local gpu = component.proxy(component.list("gpu")())
local fs = component.proxy(computer.getBootAddress())
local w,h = gpu.getResolution()
_G.rawFs = fs
local x = 1
local y = 1

 local pcps = computer.pullSignal

local function split (inputstr, sep)

        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end
 local function splitByChunk(text, chunkSize)
     local s = {}
     for i=1, #text, chunkSize do
         s[#s+1] = text:sub(i,i+chunkSize - 1)
     end
     return s
 end

 local logfile = 0
 local logsToWrite = ""
 local loggingHandle = nil

function _G.kern_info(msg,state)
  if type(state) == "nil" then
    state = "info"
  end
  if type(msg) ~= "string" then return end
  if #split(msg,"\n") > 1 then
    for k,v in ipairs(split(msg,"\n\r")) do
      kern_info(v,state)
    end
  end
  local lc = gpu.getForeground()
  local c = 0xffffff
  local pre = "["..computer.uptime()-OS_LOGGING_START_TIME.."] "
    local num = math.floor(computer.uptime()*1000)/1000-OS_LOGGING_START_TIME
    local num_width = #tostring(num)
    if num_width > OS_LOGGING_MAX_NUM_WIDTH then
        OS_LOGGING_MAX_NUM_WIDTH = num_width
    end

  if state == "info" then
    pre = "["..string.rep(" ",OS_LOGGING_MAX_NUM_WIDTH-(num_width/2))..""..num..""..string.rep(" ",OS_LOGGING_MAX_NUM_WIDTH-(num_width/2)-(num_width/2)).."] ".."[   OK   ]"
    c = 0x10ff10
  elseif state == "warn" then
    c = 0xff10ff
    pre = "["..string.rep(" ",OS_LOGGING_MAX_NUM_WIDTH-(num_width/2))..""..num..""..string.rep(" ",OS_LOGGING_MAX_NUM_WIDTH-(num_width/2)-(num_width/2)).."] ".. "[  WARN  ]"
  elseif state == "error" then
    c = 0xff1010
    pre = "["..string.rep(" ",OS_LOGGING_MAX_NUM_WIDTH-(num_width/2))..""..num..""..string.rep(" ",OS_LOGGING_MAX_NUM_WIDTH-(num_width/2)-(num_width/2)).."] ".. "[ ERROR  ]"
  end
    if OSSTATUS < 1 then
        logsToWrite = logsToWrite..pre.." "..msg.."\n"
        gpu.setForeground(c)

        gpu.set(x,y,pre.." "..msg)
        x = 1
        if y > h-1 then
            gpu.copy(1,1,w,h,0,-1)
            gpu.fill(1,h,w,1," ")
        else
            y = y+1
        end
        gpu.setForeground(lc)
    else
        local fs = require("fs")
        if type(loggingHandle) == "nil" then
            logsToWrite = logsToWrite..pre.." "..msg.."\n"
            return
        end

        loggingHandle:write(pre.." "..msg.."\n")
        logsToWrite = ""



    end
end

gpu.fill(1,1,w,h," ")

 function _G.kern_panic(reason)
   kern_info("KERNEL PANIC","error")
   kern_info("A kernel panic occured! Traceback:", "error")
   kern_info("----------------------------------------------------","error")
   kern_info(debug.traceback(), "error")
   kern_info("----------------------------------------------------","error")
   kern_info("Panic reason: "..reason, "error")
   while true do
     pcps()
   end

 end


 function _G.raw_dofile(file)
  local program, reason = raw_loadfile(file)
  --kernel_info(file.." and is the: "..program)
     kern_info("Loading file "..file)
  if program then
    local result = table.pack(xpcall(program,debug.traceback))
    if result[1] then
        kern_info("Successfully loaded file "..file)

      return table.unpack(result, 2, result.n)
    else
        kern_info("Error loading file "..file, "error")

      error(result[2].." is the error")
    end
  else
      kern_info("Error loading file "..file, "error")

    error(reason)
  end
end

 local function bsod(reason,isKern)
     if gpu then
         gpu.setBackground(0x2665ed)
         gpu.setForeground(0xffffff)
         gpu.fill(1,1,w,h," ")
         gpu.set(10,10,"Oops! Something went wrong!")
         gpu.set(10,11,"BSOD reason: ")
         local splitReason = split(reason,"\n")
         local kaka = 1
         for k,v in ipairs(splitReason) do
             gpu.set(10,12+k,v)
             kaka = k
         end
         gpu.set(10,12+kaka+1,"Details:")
         local splitTrace = split(debug.traceback(),"\n")
         local ka = 1
         for k,v in ipairs(splitTrace) do
             gpu.set(10,13+ka+kaka,v)
             ka = k
         end

     end
     if not isKern then
         while true do
             pcps()
         end
     else
         return reason
     end
 end

kern_info("Loading package managment...")
local package = raw_dofile("/lib/package.lua")

_G.package = package
package.loaded = {}
package.loaded.component = component
package.loaded.computer = computer
package.loaded.filesystem = fs
package.loaded.package = package

 kern_info("Mounting system drive")
 local fs = package.require("fs")
 fs.mount(rawFs, "/")


 kern_info("Loading drivers...")

 local driver = package.require("driver")

 for ka,va in fs.list("/driver/") do
     for k,v in fs.list("/driver/"..ka) do
         kern_info("Giving direct component proxy access to driver "..ka..k)
         --computer.pullSignal(0.5)
         local d = driver.getDriver(ka..k)
         d.cp = {
             proxy = component.proxy,
             list = component.list,
             get = component.get,
             invoke = component.invoke,
             methods = component.methods,

         }
     end

 end


kern_info("Loading other files...")



local function rom_invoke(method, ...)
  return component_invoke(computer.getBootAddress(), method, ...)
end

local scripts = {}
for _, file in ipairs(rom_invoke("list", "PlotOS/system32/boot/")) do
  local path = "PlotOS/system32/boot/" .. file
  if not rom_invoke("isDirectory", path) then
      kern_info("Indexed boot script at "..path)
    table.insert(scripts, path)
  end
end
table.sort(scripts)
for i = 1, #scripts do
  kern_info("Running boot script "..scripts[i])
  raw_dofile(scripts[i])
end

kern_info("Starting shell...")
 _G.OSSTATUS = 1
 loggingHandle = fs.open("/logs.log", "w")
 local con = splitByChunk(logsToWrite,1024)
 for k,v in ipairs(con) do
     loggingHandle:write(v)
 end

--os.sleep(2)
require("screen").clear()

dofile("/PlotOS/cursor.lua")

local e,process = xpcall(require, function(e) bsod(e,true) end, "process")
if not e then
  while true do pcps() end
end

local fs = require("fs")
local logger = require("log4po")

local s1,e1 = pcall(function()
  dofile("/PlotOS/systemAutorun.lua")
end)

if not s1 then
  logger.error("Error running system autorun: "..e1)
end

local s2,e2 = pcall(function()
  dofile("/autorun.lua")
end)

if not s2 then
  logger.error("Error running autorun: "..e2)
end

process.autoTick()
computer.beep(1000)
kern_panic("System halted!")