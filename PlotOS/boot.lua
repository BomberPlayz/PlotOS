 local raw_loadfile = ...

_G.OSNAME = "PlotOS"
_G.OSVERSION = "0.0.3"
_G.OSRELEASE = "alpha"

local gpu = component.proxy(component.list("gpu")())
local fs = component.proxy(computer.getBootAddress())
local w,h = gpu.getResolution()
_G.rawFs = fs
local x = 1
local y = 1

function split (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end


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
  local pre = "[ ???????? ]"
  if state == "info" then
    pre = "[   OK   ]"
    c = 0x10ff10
  elseif state == "warn" then
    c = 0xff10ff
    pre = "[  WARN  ]"
  elseif state == "error" then
    c = 0xff1010
    pre = "[ ERROR  ]"
  end
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
     computer.pullSignal()
   end

 end


 function _G.raw_dofile(file)
  local program, reason = raw_loadfile(file)
  --kernel_info(file.." and is the: "..program)
  if program then
    local result = table.pack(xpcall(program,function(e) error(debug.traceback()) end))
    if result[1] then
      return table.unpack(result, 2, result.n)
    else
      error(result[2].." is the error")
    end
  else
    error(reason.." is reeson")
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
kern_info("Loading other files...")

local function rom_invoke(method, ...)
  return component.invoke(computer.getBootAddress(), method, ...)
end

local scripts = {}
for _, file in ipairs(rom_invoke("list", "PlotOS/system32/boot/")) do
  local path = "PlotOS/system32/boot/" .. file
  if not rom_invoke("isDirectory", path) then
    table.insert(scripts, path)
  end
end
table.sort(scripts)
for i = 1, #scripts do
  kern_info("loading module --> "..scripts[i])
  raw_dofile(scripts[i])
end
kern_info("Starting shell!")
--os.sleep(2)
require("screen").clear()

dofile("/PlotOS/cursor.lua")
--local ok, reason = xpcall(dofile, erred,"/sys/shell.lua")

 local process = require("process")
 process.load("Shell", os.getEnv("SHELL"))

 process.load("cursorblink","/bin/cursorblink.lua")

 process.load("Rainmeter","/bin/rainmeter.lua")



 process.autoTick()

computer.beep(1000)
kern_panic("System halted!")