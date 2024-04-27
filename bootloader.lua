-- foundation
_G.KERN_PARAMS = {}

local kernPath = "/PlotOS/boot.lua"

do
  local gpu = component.list("gpu")()
  local cinv = component.invoke

  local w,h = cinv(gpu, "getResolution")

  -- https://gist.github.com/PatriikPlays/459cac4c65858dd35317638730352d30
  local mio = (function(gpu,fg,bg)local b,c=cinv(gpu,"getResolution")local d,e,f,cinv=1,1,{},component.invoke;function f.scroll()cinv(gpu,"copy",1,1,b,c,0,-1)cinv(gpu,"fill",1,c,b,1," ")end;function f.write(g)cinv(gpu,"set",d,e,g)d=d+#g end;function f.writeLine(g)cinv(gpu,"set",d,e,g)d=1;e=e+1;if e==c then f.scroll()e=e-1 end end;function f.reset()cinv(gpu,"setForeground",fg)cinv(gpu,"setBackground",bg)end;function f.resetInv()cinv(gpu,"setForeground",bg)cinv(gpu,"setBackground",fg)end;function f.clear()d=1;e=1;f.reset()cinv(gpu,"fill",1,1,b,c," ")end;function f.read()local h=""local i=false;while true do local j,k,l=computer.pullSignal(0.5)i=not i;if i then f.resetInv()else f.reset()end;cinv(gpu,"set",d,e,({cinv(gpu,"get",d,e)})[1])f.reset()if j=="key_down"then if l==13 then cinv(gpu,"set",d,e,({cinv(gpu,"get",d,e)})[1])d=1;e=e+1;if e==c then f.scroll()e=e-1 end;return h end;if l==8 then if#h>0 then cinv(gpu,"set",d,e,({cinv(gpu,"get",d,e)})[1])d=d-1;cinv(gpu,"set",d,e," ")h=h:sub(1,-2)end elseif l==127 then elseif l>31 then if b>d+1 then h=h..string.char(l)cinv(gpu,"set",d,e,({cinv(gpu,"get",d,e)})[1])f.write(string.char(l))end end end end;return h end;return f end)(gpu,0xFFFFFF,0x000000)
  mio.clear()

  local function waitForKey(timeout)
    local endTime = computer.uptime() + timeout
    while true do
      if computer.uptime() >= endTime then
        return false
      end
      local ev, _, char = computer.pullSignal(endTime - computer.uptime())
      if ev == "key_down" then
        if char == 13 then
          return true
        elseif char == 32 then
          return false
        end
      end
    end
  end

  local function kernConfig()
    local function kernPathConfig()
      mio.clear()

      mio.writeLine("Leave empty to keep defaults")
      mio.writeLine("")
      mio.write("Kernel path (".. kernPath .."): ")
      local res = mio.read()
      if #res > 0 then kernPath = res end
    end

    local function custom()

    end

    local function toggleSafeMode()
      KERN_PARAMS["SAFE_MODE"] = not KERN_PARAMS["SAFE_MODE"] or nil
    end

    local function toggleVLM()
      KERN_PARAMS["VERY_LOW_MEM"] = not KERN_PARAMS["VERY_LOW_MEM"] or nil
    end

    local function shell()
      mio.clear()
      mio.writeLine(tostring(_VERSION))
      while true do
        mio.write("> ")
        local inp = mio.read()
        if inp == "exit" then
          break
        end
        if #inp > 0 then
          local s,e1 = load("return "..inp, "=shell", nil, _ENV)

          if not s then s = load(inp, "=shell", nil, _ENV) end

          if s then
            local ok, res = pcall(s)
            if ok then
              mio.writeLine(tostring(res))
            else
              mio.writeLine("Err: "..tostring(res))
            end
          else
            mio.writeLine("Err: "..tostring(e1))
          end
        end
      end
    end

    local function main()
      while true do
        mio.clear()
        local kparamStr = ""
        for k,v in pairs(KERN_PARAMS) do
          kparamStr = kparamStr .. k .. "=" .. tostring(v) .. " "
        end

        mio.writeLine("Kernel params: ".. kparamStr)
        mio.writeLine("Kernel path: ".. kernPath)

        mio.writeLine("")
        mio.writeLine("Select an option:")
        mio.writeLine("1. Toggle safe mode")
        mio.writeLine("2. Toggle very low mem")
        mio.writeLine("3. Set kernel path")
        mio.writeLine("4. Custom - NOT IMPLEMENTED")
        mio.writeLine("5. LUA shell")
        mio.writeLine("Enter - Quit")

        
        while true do
          local ev, _, char = computer.pullSignal()
          if ev == "key_down" then
            if char == 49 then
              toggleSafeMode()
              break
            elseif char == 50 then
              toggleVLM()
              break
            elseif char == 51 then
              kernPathConfig()
              break
            elseif char == 52 then
              custom()
              break
            elseif char == 53 then
              shell()
              break
            elseif char == 13 then
              return
            end
          end
        end
      end
    end

    main()
  end

  mio.writeLine("Hello from foundation!")
  mio.writeLine("")
  mio.writeLine("Components: ")
  for k,v in pairs(component.list()) do
    mio.writeLine(k .. ": " .. v)
  end

  mio.writeLine("")
  mio.writeLine("Used:")
  mio.writeLine("GPU: " .. gpu)
  mio.writeLine("Disk: " .. computer.getBootAddress())

  mio.writeLine("")
  mio.writeLine("Info:")
  mio.writeLine("Memory Total: " .. computer.totalMemory() .. "b")
  mio.writeLine("GPU Resolution: " .. w .. "x" .. h)


  mio.writeLine("")
  mio.writeLine("Press enter for boot options, space to skip... (5s)")
  local enterOpts = waitForKey(5)
  
  if enterOpts then
    kernConfig()
  else
    mio.writeLine("Bye!")
  end
end

return kernPath