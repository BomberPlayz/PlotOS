local raw_loadfile = ...

_G.OSNAME = "PlotOS"
_G.OSVERSION = "0.0.4"
_G.OSRELEASE = "alpha"
_G.OSSTATUS = 0
_G.OS_LOGGING_START_TIME = math.floor(computer.uptime() * 1000) / 1000
_G.OS_LOGGING_MAX_NUM_WIDTH = 0

_G.VERY_LOW_MEM = _G.KERN_PARAMS.VERY_LOW_MEM or false

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

-- early-import streams
local Stream = raw_loadfile("/lib/stream.lua")() -- FIXME: this is a hack

local logStream = Stream.new()
--- Logs a message with a specified state and formatting
--- @param msg string|any Message to be logged (will be converted to string)
--- @param state string|nil Log level ('debug'|'info'|'warn'|'error'). Defaults to 'info'
--- Handles multi-line messages by splitting and logging each line separately
--- Formats output with timestamp, state label, and color coding
--- Before system initialization (OSSTATUS < 1):
---   - Displays logs on screen with GPU
---   - Manages screen scrolling when reaching bottom
--- After system initialization:
---   - Writes logs to file through loggingHandle
--- Global function available through _G
---@see OS_LOGGING_START_TIME
---@see OSSTATUS
---@see loggingHandle
---@see logsToWrite
function _G.printk(msg, state)
    
    -- print all methods
    -- Define settings for different log states
    local log = { "debug", "info", "warn", "error" }
    local state_settings = {
        debug = { label = "[ DEBUG]", color = 0xaaaaff },
        info = { label =  "[    OK]", color = 0x10ff10 },
        warn = { label =  "[  WARN]", color = 0xff10ff },
        error = { label = "[FAILED]", color = 0xff1010 },
    }

    -- Set default state
    if not state or not state_settings[state] then
        state = "info"
    end

    local logincludes = false
    for i = 1, #log do
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
            printk(line, state)
        end
        return
    end

    -- Calculate time duration since start in seconds
    local uptime = computer.uptime() - OS_LOGGING_START_TIME
    local time_str = string.format("%.2f", uptime)

    -- Prepare message: replace tabs with spaces, prepend duration and status label
    local msg_out = string.gsub(msg, "\t", "    ")
    msg_out = string.format("[%8s] %s %s", time_str, state_settings[state].label, msg_out)
    logStream:write(msg_out .. "\n")

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
        gpu.setForeground(0xffffff) -- reset color
    else
        local fs = require("fs")
        if not loggingHandle then
            logsToWrite = logsToWrite .. msg_out .. "\n"
            return
        end
        loggingHandle:write(msg_out .. "\n")
        --loggingHandle:flush()
        logsToWrite = ""
    end
   -- ocelot.log(msg_out)
    
end

gpu.fill(1, 1, w, h, " ")

local ropen = fs.open
local rwrite = fs.write
local rclose = fs.close

---@class kern_panic
---Kernel panic handler function that logs system information and halts execution
---This function is called when a critical system error occurs that prevents normal operation
---@param reason string|any The reason for the kernel panic
---@global
---@usage kern_panic("Critical system error occurred")
---
---Performs the following actions:
---1. Logs the panic reason and stack trace
---2. Dumps system information (OS details, status, addresses)
---3. Logs hardware information (architecture, memory, GPU)
---4. Lists all connected components
---5. Logs environment state
---6. Attempts to save logs to /panic.log
---7. Halts the system
---
---Requires global variables:
---* OSNAME: string - Operating system name
---* OSVERSION: string - Operating system version
---* OSRELEASE: string - Operating system release
---* OSSTATUS: number - Operating system status
---* LOW_MEM: boolean - Low memory flag
---* VERY_LOW_MEM: boolean - Critical low memory flag
---
---Required components:
---* computer
---* component
---* gpu
function _G.kern_panic(reason)
    printk("KERNEL PANIC", "error")
    printk("----------------------------------------------------", "error")
    printk("Panic reason: " .. tostring(reason), "error")
    printk("----------------------------------------------------", "error")
    
    -- Stack trace
    printk("Stack trace:", "error")
    printk(debug.traceback("", 2), "error")
    printk("----------------------------------------------------", "error")

    -- System info
    printk("System Information:", "error")
    printk(string.format("OS: %s %s-%s", OSNAME, OSVERSION, OSRELEASE), "error")
    printk(string.format("Status: %d, Uptime: %.2fs", OSSTATUS, computer.uptime()), "error")
    printk(string.format("Boot Address: %s", computer.getBootAddress()), "error")
    printk(string.format("Machine Address: %s", computer.address()), "error")
    
    -- Hardware info
    printk("Hardware Information:", "error")
    printk(string.format("Architecture: %s", computer.getArchitecture()), "error")
    printk(string.format("Memory: %dKB total, %dKB free", 
        math.floor(computer.totalMemory() / 1024),
        math.floor(computer.freeMemory() / 1024)), "error")
    printk(string.format("GPU Resolution: %dx%d", gpu.maxResolution()), "error")
    
    -- Component listing
    printk("Connected Components:", "error")
    for address, type in component.list() do
        printk(string.format("%s: %s", type, address), "error")
    end
    
    -- Environment state
    printk("Environment State:", "error")
    printk(string.format("LOW_MEM: %s, VERY_LOW_MEM: %s", 
        tostring(_G.LOW_MEM), 
        tostring(_G.VERY_LOW_MEM)), "error")

    -- Save logs
    if not _G.VERY_LOW_MEM then
        local ok, err = pcall(function()
            local handle = component_invoke(computer.getBootAddress(), "open", "/panic.log", "w")
            component_invoke(computer.getBootAddress(), "write", handle, logsToWrite)
            component_invoke(computer.getBootAddress(), "close", handle)
            printk("Logs saved to /panic.log", "error")
        end)
        if not ok then
            printk("Failed to save logs: " .. tostring(err), "error")
        end
    end

    -- System halt
    printk("System halted - Press Ctrl+Alt+C to reboot", "error")
    while true do
        pcps()
    end
end

---Loads and executes a Lua file with error handling
---@param file string The path to the Lua file to load and execute
---@return any ... Returns all results from the executed file on success
---@throws string Error message if file loading or execution fails
---@see raw_loadfile
---@see xpcall
---@see debug.traceback
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
            printk("Error loading file " .. file, "error")
            printk("Error: " .. result[2], "error")
            error(result[2] .. " is the error")
        end
    else
        printk("Error loading file " .. file, "error")
        printk("Error: " .. reason, "error")

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
        kern_panic(reason)
    else
        kern_panic(reason)
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

local bootType = KERN_PARAMS.SAFE_MODE and BootTypeEnum.PlotOS.safe or BootTypeEnum.PlotOS.normal

if _G.VERY_LOW_MEM then
    _G.printk = function() end
    _G.kern_panic = function(reason)
        local w, h = gpu.getResolution()
        gpu.setForeground(0xff0000)
        gpu.setBackground(0x000000)
        gpu.fill(1, 1, w, h, " ")
        gpu.set(1, 1, "KERNEL PANIC: " .. tostring(reason))
        gpu.set(1, 2, "A kernel panic occured! Traceback:")

        local tb = debug.traceback("", 2)
        for i, v in ipairs(split(tb, "\n")) do
            gpu.set(1, 3 + i, ({ v:gsub("\009", "    ") })[1])
        end

        while true do
            pcps()
        end
    end
    _G.bsod = _G.kern_panic
end

--[[BOOT]]
--
local function initRegistry(reg)
    local newSystem, newUserRoot
    do
        local ok, err, new = reg.mount("/PlotOS/system32/registry/system.reg", "system", true)
        newSystem = new
    end
    do
        local ok, err, new = reg.mount("/PlotOS/system32/registry/user_root.reg", "user_root", true)
        newUserRoot = new
    end


    if newSystem then
        printk("Creating system registry")
        reg.set("system/boot/safemode", 0, reg.types.u8, true)
        reg.set("system/security/disable", 0, reg.types.u8, true)
        reg.set("system/processes/attach_security", 1, reg.types.u8, true)
        reg.set("system/security/driver_crash_bsod", 1, reg.types.u8, true)
        reg.set("system/shell", "/bin/shell.lua", reg.types.string, true)
        reg.set("system/ui/window/drag_borders", 1, reg.types.u8, true)
        reg.set("system/ui/window/shadow_on_drag", 1, reg.types.u8, true)
        reg.set("system/ui/window/shadow_always", 1, reg.types.u8, true)
        reg.set("system/ui/window/titlebar_color", 0x0000ff, reg.types.u32, true)
        reg.set("system/low_mem", -1, reg.types.s8, true)
        reg.set("system/registry/use_tmp_files_to_save", -1, reg.types.s8, true)
        reg.save("system")
    end

    if newUserRoot then
        printk("Creating user_root registry")
        reg.set("user_root/home", "/users/root", reg.types.string, true)
        reg.set("user_root/username", "root", reg.types.string, true)
        reg.set("user_root/password", "test", reg.types.string, true)
        reg.set("user_root/uid", 1, reg.types.u32, true)
        reg.set("user_root/groups/1", "root", reg.types.string, true)
        reg.set("user_root/permissions/1", "*", reg.types.string, true)
        reg.set("system/users/1/reg_path", "user_root", reg.types.string, true)
        reg.set("system/users/1/name", "root", reg.types.string, true)
        reg.save("user_root")
        reg.save("system")
    end

    local useTmpFilesToSaveEnabled = reg.get("system/registry/use_tmp_files_to_save")
    if useTmpFilesToSaveEnabled == 0 then
        reg.useTmpFilesToSave = false
        printk("Registry use tmp files to save disabled")
    elseif useTmpFilesToSaveEnabled == 1 then
        reg.useTmpFilesToSave = true
        printk("Registry use tmp files to save enabled")
    else
        if reg.useTmpFilesToSave then
            printk("Registry use tmp files to save enabled")
        else
            printk("Registry use tmp files to save disabled")
        end
    end

    local lowMemEnabled = reg.get("system/low_mem")
    if lowMemEnabled == 1 and _G.LOW_MEM == false then
        _G.LOW_MEM = true
        printk("LOW_MEM mode enabled")
    end
end

local function initBoot(type)
    if computer.totalMemory() <= 262144 then
        _G.LOW_MEM = true
        printk("LOW_MEM mode enabled")
    else
        _G.LOW_MEM = false
        printk("LOW_MEM mode disabled")
    end
    printk("Hell debug", "debug")
    printk("Loading package managment...")
    local package = raw_dofile("/lib/package.lua")

    _G.package = package
    package.loaded = {}
    package.loaded.component = component
    package.loaded.computer = computer
    package.loaded.filesystem = fs
    package.loaded.package = package

    printk("Mounting system drive")
    local fs = package.require("fs")
    fs.mount(rawFs, "/")

    printk("Initializing registry")

    local reg = package.require("registry")
    initRegistry(reg)
    initRegistry = nil

    local safemode = false

    if type ~= BootTypeEnum.None then
        if type == BootTypeEnum.PlotOS.safe then
            safemode = true
        elseif type == BootTypeEnum.PlotOS.normal then
            safemode = false
        end
    else
        printk("SAMA::" .. tostring(reg.get("system/boot/safemode")))

        if reg.get("system/boot/safemode") == 1 then
            safemode = true
        else
            safemode = false
        end
    end

    if safemode == "true" then
        printk("Safemode is enabled!", "warn")
        safemode = true
    end

    printk("Loading drivers...")

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

    printk("Doing some user magic...")
    local user = package.require("libuser")

    printk("Loading other files...")

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
        printk("Loaded " .. #scripts .. " boot scripts.")
    else
        printk("Safemode is enabled, loading only critical bootscripts.")
        scripts = { "/PlotOS/system32/boot/00_base.lua", "/PlotOS/system32/boot/05_OS.lua",
            "/PlotOS/system32/boot/80_io.lua", "/PlotOS/system32/safemode_component.lua",
            "/PlotOS/system32/boot/01_overrides.lua", "/PlotOS/system32/safemode_warn.lua",
            "/PlotOS/system32/zzzz_safemode_shell.lua" }
    end
    table.sort(scripts)
    
    do
        loggingHandle = fs.open("/logs.log", "w")
        local con = splitByChunk(logsToWrite, 1024)
        for k, v in ipairs(con) do
            loggingHandle:write(v)
        end
    end

    return scripts
end

local bootScripts
do
    local ok, res = xpcall(initBoot, function(e)
        return tostring(e) .. "\n" .. tostring(debug.traceback("", 2))
    end, bootType)

    if not ok then
        kern_panic("Critical system failiure: " .. tostring(res))
    end

    bootScripts = res
end

return bootScripts