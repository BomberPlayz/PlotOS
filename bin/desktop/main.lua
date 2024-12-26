local fs = require("fs")
local gui = require("newgui")
local process = require("process")
local gpu = require("driver").load("gpu")
local reg = require("registry")
local event = require("event")

-- Desktop configuration
local ICON_WIDTH = 12
local ICON_HEIGHT = 6
local GRID_PADDING = 2
local TASKBAR_HEIGHT = 1

-- Create desktop
local desktop = gui.panel(0, 0, gpu.getResolution())
desktop.color = reg.get("system/ui/desktop/background_color") or 0x223344

-- Create taskbar
local taskbar = gui.panel(1, desktop.h - TASKBAR_HEIGHT + 1, desktop.w, TASKBAR_HEIGHT)
taskbar.color = reg.get("system/ui/taskbar/background_color") or 0x334455
desktop.addChild(taskbar)

-- Create start button
local startButton = gui.button(1, 1, 6, 1, "Start")
startButton.backgroundColor = reg.get("system/ui/taskbar/button_color") or 0x445566
taskbar.addChild(startButton)

-- Create start menu
local startMenu = gui.contextmenu({
    { text = "Programs", submenu = true },
    { text = "Settings", action = function() process.load("settings", "/bin/settings.lua") end },
    { text = "-" }, -- separator
    { text = "Shutdown", action = function() computer.shutdown() end },
    { text = "Reboot", action = function() computer.shutdown(true) end },
})
desktop.addChild(startMenu)

startButton.eventbus.on("click", function()
    startMenu.showAt(1, desktop.h - #startMenu.items - 1)
end)

-- Desktop icon container
local iconContainer = gui.container(1, 1, desktop.w, desktop.h - TASKBAR_HEIGHT)
desktop.addChild(iconContainer)

-- Function to create desktop icon
local function createDesktopIcon(name, path)
    local icon = gui.container(0, 0, ICON_WIDTH, ICON_HEIGHT)
    icon.color = desktop.color
    
    -- Icon button
    local btn = gui.button(0, 0, ICON_WIDTH, ICON_HEIGHT - 1, "")
    btn.backgroundColor = desktop.color
    btn.draw_shadow = false
    icon.addChild(btn)
    
    -- Icon label
    local label = gui.label(0, ICON_HEIGHT - 1, ICON_WIDTH, 1, name)
    label.color = 0xFFFFFF
    label.background = desktop.color
    icon.addChild(label)
    
    -- Interaction handling
    local lastClickTime = 0
    btn.eventbus.on("click", function()
        local currentTime = computer.uptime()
        if currentTime - lastClickTime < 0.3 then
            -- Double click
            process.load(name, path)
        end
        lastClickTime = currentTime
    end)
    
    return icon
end

-- Layout desktop icons in a grid
local function layoutIcons()
    local x, y = GRID_PADDING, GRID_PADDING
    local maxIcons = math.floor((iconContainer.w - GRID_PADDING) / (ICON_WIDTH + GRID_PADDING))
    
    -- Clear existing icons
    iconContainer.children = {}
    
    -- Add program icons
    local files = fs.list("/bin")
    for f in files do
        -- Skip system files and hidden files
        if not f:match("^%.") and f ~= "desktop" then
            local icon = createDesktopIcon(f, "/bin/" .. f)
            icon.x = x
            icon.y = y
            iconContainer.addChild(icon)
            
            x = x + ICON_WIDTH + GRID_PADDING
            if x + ICON_WIDTH > iconContainer.w then
                x = GRID_PADDING
                y = y + ICON_HEIGHT + GRID_PADDING
            end
        end
    end
end

-- Initial layout
layoutIcons()

-- Add desktop to workspace
gui.workspace.addChild(desktop)

-- Handle screen resolution changes
event.listen("resolution_change", function()
    desktop.w, desktop.h = gpu.getResolution()
    taskbar.w = desktop.w
    taskbar.y = desktop.h - TASKBAR_HEIGHT + 1
    iconContainer.w = desktop.w
    iconContainer.h = desktop.h - TASKBAR_HEIGHT
    layoutIcons()
    desktop.setDirty()
end)
