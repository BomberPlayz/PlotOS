local raw_loadfile = ...

_G.OSNAME = "PlotOS"
_G.OSVERSION = "0.0.3"
_G.OSRELEASE = "alpha"
_G.OSSTATUS = 0
_G.OS_LOGGING_START_TIME = math.floor(computer.uptime() * 1000) / 1000
_G.OS_LOGGING_MAX_NUM_WIDTH = 0

_G.VERY_LOW_MEM = false

local component_invoke = component.invoke

local function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local function splitByChunk(text, chunkSize)
    local s = {}
    for i = 1, #text, chunkSize do
        s[#s + 1] = text:sub(i, i + chunkSize - 1)
    end
    return s
end

local gpu = component.proxy(component.list("gpu")())
local fs = component.proxy(computer.getBootAddress())
local rawfs = fs
local w, h = gpu.getResolution()
_G.rawFs = fs
local x = 1
local y = 1

local pcps = computer.pullSignal

local logfile = 0
local logsToWrite = ""
local loggingHandle = nil

function _G.kern_info(msg, state)
    -- Define settings for different log states
    local log = {"debug", "info", "warn", "error"}
    local state_settings = {
        debug = { label = "[ DEBUG]", color = 0xaaaaff },
        info = { label = "[  OK  ]", color = 0x10ff10 },
        warn = { label = "[ WARN ]", color = 0xff10ff },
        error = { label = "[FAILED]", color = 0xff1010 },
    }

    -- Set default state
    if not state or not state_settings[state] then
        state = "info"
    end

    local logincludes = false
    for i=1,#log do
      if log[i] == state then
        logincludes = true
      end
    end
    if not logincludes then
      return
    end

    -- Make sure we have a valid message string
    msg = tostring(msg)

    -- If message contains multiple lines, call this function recursively for each line
    local lines = split(string.gsub(msg, "\r?\n", "\n"), "\n")
    if #lines > 1 then
        for _, line in ipairs(lines) do
            kern_info(line, state)
        end
        return
    end

    -- Calculate time duration since start in seconds
    local uptime = computer.uptime() - OS_LOGGING_START_TIME
    local time_str = string.format("%.2f", uptime)

    -- Prepare message: replace tabs with spaces, prepend duration and status label
    local msg_out = string.gsub(msg, "\t", "    ")
    msg_out = string.format("[%8s] %s %s", time_str, state_settings[state].label, msg_out)

    if OSSTATUS < 1 then
        logsToWrite = logsToWrite .. msg_out .. "\n"
        gpu.setForeground(state_settings[state].color)
        gpu.set(x, y, msg_out)
        x = 1
        if y > h - 1 then
            gpu.copy(1, 1, w, h, 0, -1)
            gpu.fill(1, h, w, 1, " ")
        else
            y = y + 1
        end
        gpu.setForeground(0xffffff)  -- reset color
    else
        local fs = require("fs")
        if not loggingHandle then
            logsToWrite = logsToWrite .. msg_out .. "\n"
            return
        end
        loggingHandle:write(msg_out .. "\n")
        logsToWrite = ""
    end
end

gpu.fill(1, 1, w, h, " ")

local ropen = fs.open
local rwrite = fs.write
local rclose = fs.close

function _G.kern_panic(reason)
    kern_info("KERNEL PANIC", "error")
    kern_info("A kernel panic occured! Traceback:", "error")
    kern_info("----------------------------------------------------", "error")

    -- use debug to get traceback
    kern_info(debug.traceback("", 2), "error")
    kern_info("----------------------------------------------------", "error")
    --[[kern_info("Variable dump:", "error")
    kern_info("----------------------------------------------------", "error")
    -- use debug to get all variables
    function get_vars()
        local vars = ""
        local level = 2
        while true do
            local i = 1
            while true do
                local name, value = debug.getlocal(level, i)
                if not name then
                    break
                end
                vars = vars .. "\t" .. tostring(name) .. " = " .. tostring(value) .. "\n"
                i = i + 1
            end
            level = level + 1
            if not debug.getinfo(level) then
                break
            end
        end
        return vars
    end
    kern_info(get_vars(), "error")
    -- also dump all globals, right here
    function get_globals()
        local vars = ""
        for k, v in pairs(_G) do
            vars = vars .. "\t" .. tostring(k) .. " = " .. tostring(v) .. "\n"
        end
        return vars
    end
    kern_info(get_globals(), "error")
    kern_info("----------------------------------------------------", "error")
    kern_info("Hardware info:", "error")
    kern_info("----------------------------------------------------", "error")
    kern_info("CPU: " .. computer.getArchitecture(), "error")
    kern_info("RAM: " .. tostring(math.floor(computer.totalMemory() / 1024)) .. " KB", "error")
    kern_info("GPU: " .. tostring(gpu.maxResolution()) .. "x" .. tostring(gpu.maxResolution()), "error")
    kern_info("----------------------------------------------------", "error")
    kern_info("Connected components:", "error")
    function get_components()
        local vars = ""
        for k, v in pairs(component.list()) do
            vars = vars .. "\t" .. tostring(k) .. " = " .. tostring(v) .. "\n"
        end
        return vars
    end
    kern_info(get_components(), "error")
    kern_info("----------------------------------------------------", "error")
    kern_info("System info:", "error")
    kern_info("----------------------------------------------------", "error")
    kern_info("OS: " .. OSNAME .. " " .. OSVERSION, "error")
    kern_info("OS Status: " .. tostring(OSSTATUS), "error")
    kern_info("----------------------------------------------------", "error")
    kern_info("System time: " .. tostring(computer.uptime()), "error")
    kern_info("System uptime: " .. tostring(computer.uptime()), "error")
    kern_info("----------------------------------------------------", "error")
    kern_info("System boot address: " .. tostring(computer.getBootAddress()), "error")
    kern_info("System address: " .. tostring(computer.address()), "error")]]

    kern_info("Panic reason: " .. reason, "error")
    -- save logs
    -- use the raw filesystem API to avoid any errors
    function save()
        if _G.VERY_LOW_MEM then return end
        --[[ local handle = ropen("/logs.log", "w")
         rwrite(handle, logsToWrite)
         rclose(handle)]]
        local handle = component_invoke(computer.getBootAddress(), "open", "/logs.log", "w")
        component_invoke(computer.getBootAddress(), "write", handle, logsToWrite)
        component_invoke(computer.getBootAddress(), "close", handle)

        kern_info("Logs saved to /logs.log", "error")
    end
    local ok, err = pcall(save)
    if not ok then
        kern_info("Failed to save logs: " .. err, "error")
    end

    while true do
        pcps()
    end
end

if _G.VERY_LOW_MEM then 
    _G.kern_info = function() end
    _G.kern_panic = function(reason)
        local w,h = gpu.getResolution()
        gpu.setForeground(0xff0000)
        gpu.setBackground(0x000000)
        gpu.fill(1,1,w,h," ")
        gpu.set(1,1,"KERNEL PANIC: "..tostring(reason))
        gpu.set(1,2,"A kernel panic occured! Traceback:")

        local tb = debug.traceback("", 2)
        for i,v in ipairs(split(tb,"\n")) do
            gpu.set(1, 3+i, ({v:gsub("\009", "    ")})[1])
        end

        while true do
            pcps()
        end
    end
end

function _G.raw_dofile(file)
    local program, reason = raw_loadfile(file)
    --kernel_info(file.." and is the: "..program)
   -- kern_info("Loading file " .. file)
    if program then
        local result = table.pack(xpcall(program, debug.traceback))
        if result[1] then
          --  kern_info("Successfully loaded file " .. file)

            return table.unpack(result, 2, result.n)
        else
            kern_info("Error loading file " .. file, "error")
            kern_info("Error: " .. result[2], "error")
            error(result[2] .. " is the error")
        end
    else
        kern_info("Error loading file " .. file, "error")
        kern_info("Error: " .. reason, "error")

        error(reason)
    end
end

_G.bsod = function(reason, isKern, stack)
    if gpu then
        gpu.setBackground(0x2665ed)
        gpu.setForeground(0xffffff)
        gpu.fill(1, 1, w, h, " ")
        gpu.set(10, 10, "Oops! Something went wrong!")
        gpu.set(10, 11, "reason: ")
        local splitReason = split(reason, "\n")
        local kaka = 1
        for k, v in ipairs(splitReason) do
            gpu.set(10, 12 + k, v)
            kaka = k
        end
        gpu.set(10, 12 + kaka + 1, "Details:")
        if stack == nil then
            stack = debug.traceback("", 2)
        end
        local splitTrace = split(stack, "\n\r\t")
        local ka = 1
        for k, v in ipairs(splitTrace) do
            gpu.set(10, 13 + ka + kaka, v)
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

local BootTypeEnum = {
    None = "none",
    PlotOS = {
        normal = "plotos_norm",
        safe = "plotos_safe"
    }
}

local bootType = BootTypeEnum.None

local function bootSelect()
    local function gpuSetCentered(y, text)
        local x = gpu.getResolution()
        local textWidth = string.len(text)
        local xPos = math.floor((x / 2) - (textWidth / 2))
        gpu.set(xPos, y, text)
    end

    local opts = {}
    local function addOption(name, func)
        table.insert(opts, { name, func })
    end

    local function selection()
        local sel = 1

        while true do
            gpu.setForeground(0xffffff)
            gpu.setBackground(0x000000)
            gpu.fill(1, 1, w, h, " ")
            gpuSetCentered(2, "Select an option:")
            for i, v in ipairs(opts) do
                if i == sel then
                    gpu.setBackground(0xeeeeee)
                    gpu.setForeground(0x000000)
                else
                    gpu.setBackground(0x000000)
                    gpu.setForeground(0xffffff)
                end

                gpuSetCentered(i + 2, v[1])
            end

            local ev, _, _, key = computer.pullSignal(0.5)
            if ev == "key_down" then
                if key == 200 then
                    sel = sel - 1
                    if sel < 1 then
                        sel = #opts
                    end
                elseif key == 208 then
                    sel = sel + 1
                    if sel > #opts then
                        sel = 1
                    end
                elseif key == 28 then
                    gpu.setForeground(0xffffff)
                    gpu.setBackground(0x000000)
                    gpu.fill(1, 1, w, h, " ")
                    return opts[sel][2]()
                end
            end
        end
        gpu.setForeground(0xffffff)
        gpu.setBackground(0x000000)
        gpu.fill(1, 1, w, h, " ")
    end

    addOption("PlotOS", function()
        bootType = BootTypeEnum.PlotOS.normal
    end)

    addOption("PlotOS with safemode", function()
        bootType = BootTypeEnum.PlotOS.safe
    end)

    selection()
end

local doBootSelection = false
local try = 0
gpu.set(1, h, "Press delete to enter boot selection")
while true do
    if try > 2 then
        break
    end
    local ev, _, _, key = computer.pullSignal(0.5)
    if ev == "key_down" then
        if key == 211 then
            doBootSelection = true
            break
        end
    elseif ev == nil then
        try = try + 1
    end
end
gpu.fill(1, 1, w, h, " ")

if doBootSelection then
    bootSelect()
end

local function endsWith(str, suffix)
    return string.sub(str, -#suffix) == suffix
end

--[[BOOT]]--
local function boot(type)
    if computer.totalMemory() <= 262144 then
        _G.LOW_MEM = true
        kern_info("LOW_MEM mode enabled")
    else
        _G.LOW_MEM = false
        kern_info("LOW_MEM mode disabled")
    end
    kern_info("Hell debug", "debug")
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

    kern_info("Initializing registry")
    kern_info("Removing stale registry locks")

    local registryLocks = fs.list("/PlotOS/system32/registry/locks")

    local registryLockCount = 0
    for lock in registryLocks do
        fs.remove("/PlotOS/system32/registry/locks/" .. lock)
        registryLockCount = registryLockCount + 1
        kern_info("Removing stale registry lock " .. lock, "warn")
    end
    if registryLockCount == 0 then
        kern_info("Found no stale registry locks")
    end

    registryLocks = nil
    registryLockCount = nil

    kern_info("Cleaning up stale registry temporary files")
    local registryFiles = fs.list("/PlotOS/system32/registry")

    local registryTmpCount = 0
    for file in registryFiles do
        if not fs.isDirectory("/PlotOS/system32/registry/"..file) then
            if endsWith(file,".tmp") then
                local msg = "Found registry tmp file: "..file
                local nonTmp = string.sub(file, 1, #file-4)
                if fs.exists("/PlotOS/system32/registry/"..nonTmp) then
                    fs.remove("/PlotOS/system32/registry/"..file)
                    msg = msg .. ", deleting"
                else
                    fs.rename("/PlotOS/system32/registry/"..file, "/PlotOS/system32/registry/"..nonTmp)
                    msg = msg .. ", moving to "..nonTmp
                end
                kern_info(msg,"warn")
                registryTmpCount = registryTmpCount + 1
            end
        end
    end
    if registryTmpCount == 0 then
        kern_info("Found no stale registry temporary files")
    end

    registryFiles = nil
    registryTmpCount = nil

    local reg = package.require("registry")

    if not reg.exists("system") then
        kern_info("Creating system registry")
        reg.set("system/boot/safemode", 0, reg.types.u8, true)
        reg.set("system/security/disable", 0, reg.types.u8, true)
        reg.set("system/processes/attach_security", 1, reg.types.u8, true)
        reg.set("system/security/driver_crash_bsod", 1, reg.types.u8, true)
        reg.set("system/shell", "/bin/shell.lua", reg.types.string, true)
        reg.set("system/ui/window/drag_borders", 1, reg.types.u8, true)
        reg.set("system/ui/window/titlebar_color", 0x0000ff, reg.types.u32, true)
        reg.set("system/low_mem", -1, reg.types.s8, true)
        reg.set("system/registry/use_tmp_files_to_save", -1, reg.types.s8, true)
        reg.save()
    end

    local useTmpFilesToSaveEnabled = reg.get("system/registry/use_tmp_files_to_save")
    if useTmpFilesToSaveEnabled == 0 then
        reg.useTmpFilesToSave = false
        kern_info("Registry use tmp files to save disabled")
    elseif useTmpFilesToSaveEnabled == 1 then
        reg.useTmpFilesToSave = true
        kern_info("Registry use tmp files to save enabled")
    else
        if reg.useTmpFilesToSave then
            kern_info("Registry use tmp files to save enabled")
        else
            kern_info("Registry use tmp files to save disabled")
        end
    end
    useTmpFilesToSaveEnabled = nil

    local lowMemEnabled = reg.get("system/low_mem")
    if lowMemEnabled == 0 and _G.LOW_MEM == true then
        _G.LOW_MEM = false
        kern_info("LOW_MEM mode disabled")
    elseif lowMemEnabled == 1 and _G.LOW_MEM == false then
        _G.LOW_MEM = true
        kern_info("LOW_MEM mode enabled")
    end
    lowMemEnabled = nil

    local safemode = false

    if type ~= BootTypeEnum.None then
        if type == BootTypeEnum.PlotOS.safe then
            safemode = true
        elseif type == BootTypeEnum.PlotOS.normal then
            safemode = false
        end
    else
        kern_info("SAMA::" .. tostring(reg.get("system/boot/safemode")))
        if reg.get("system/boot/safemode") == 1 then
            safemode = true
        else
            safemode = false
        end
    end

    if safemode == "true" then
        kern_info("Safemode is enabled!", "warn")
        safemode = true
    end

    kern_info("Loading drivers...")

    local driver = package.require("driver")

    for ka, va in fs.list("/driver/") do
        for k, v in fs.list("/driver/" .. ka) do
           -- kern_info("Giving direct component proxy access to driver " .. ka .. k)
            --computer.pullSignal(0.5)
            local d = driver.getDriver(ka .. k)
           -- kern_info("Driver " .. ka .. k .. " is " .. d.getName())
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
    if not safemode then
        for _, file in ipairs(rom_invoke("list", "PlotOS/system32/boot/")) do
            local path = "PlotOS/system32/boot/" .. file
            if not rom_invoke("isDirectory", path) then
                --kern_info("Indexed boot script at " .. path)
                table.insert(scripts, path)
            end
        end
        kern_info("Loaded " .. #scripts .. " boot scripts.")
    else
        kern_info("Safemode is enabled, loading only critical bootscripts.")
        scripts = { "/PlotOS/system32/boot/00_base.lua", "/PlotOS/system32/boot/05_OS.lua", "/PlotOS/system32/boot/80_io.lua", "/PlotOS/system32/safemode_component.lua", "/PlotOS/system32/boot/01_overrides.lua", "/PlotOS/system32/safemode_warn.lua", "/PlotOS/system32/zzzz_safemode_shell.lua" }
    end
    table.sort(scripts)
    loggingHandle = fs.open("/logs.log", "w")
    local con = splitByChunk(logsToWrite, 1024)
    for k, v in ipairs(con) do
        loggingHandle:write(v)
    end
    for i = 1, #scripts do
        kern_info("Running boot script " .. scripts[i])
        raw_dofile(scripts[i])
    end

    --local fse = package.require("fs")




end

--[[local ok, err = pcall(boot, bootType)
if not ok then
    kern_panic("Critical system failure")
end]]
local ok, e = xpcall(boot, function(e)
    return debug.traceback("", 2), e
end, bootType)
if not ok then
    kern_panic("Critical system failure: " .. e)
end

computer.beep(1000)
kern_panic("System halted!")