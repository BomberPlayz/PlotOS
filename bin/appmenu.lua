local gui = require("newgui")
local gpu = require("driver").load("gpu")
local w, h = gpu.getResolution()
local process = require("process")
local std = require("stdlib")

local win = gui.window(math.floor(w / 4), math.floor(h / 4), math.floor(w / 2), math.floor(h / 2),
    { title = "Application Menu" })
local appcontainer = gui.panel(0, 1, math.floor(w / 2), math.floor(h / 2) - 1, 0xeeeeee)
win.addChild(appcontainer)
local function displayMsgBox(title, content)
    local msgbox = gui.window(10, 10, 40, 10, { title = title })
    msgbox.backgroundColor = 0xcccccc
    msgbox.addChild(gui.label(1, 1, 40, 10, content))
    local bat = gui.button(40 - 8, 10 - 3, 7, 1, "OK")
    bat.eventbus.on("click", function()
        msgbox.close()
    end)
    msgbox.addChild(bat)
    gui.workspace.addChild(msgbox)
end

local ctxmenu = gui.contextmenu({
    {
        text = "Start new process",
        visible = true,
        action = function()
            local win = gui.window(10, 10, 40, 10, { title = "Start new process" })
            win.content.color = 0xcccccc
            local tinp = gui.textinput(1, 1, 18, 1)
            win.addChild(tinp)
            local tbtn = gui.button(40 - 8, 10 - 3, 7, 1, "Start")

            tbtn.eventbus.on("click", function()
                local name = std.str.split(tinp.text, "/")[#std.str.split(tinp.text, "/")]
                -- does it exist tho
                if not fs.exists(tinp.text) then
                    displayMsgBox("Error", "File does not exist")
                    return
                end
                local ok, err = pcall(process.load, name, tinp.text)
                if not ok then
                    displayMsgBox("Opening failed!", err)
                end
                win.close()
            end)
            win.addChild(tbtn)
            gui.workspace.addChild(win)
        end
    }
})


local ctxmenubutton = gui.button(0, 0, 7, 1, "Program")
ctxmenubutton.eventbus.on("click", function()
    ctxmenu.showAt(0, 1)
end)
ctxmenu.eventbus.on("item_click", function(item)
    item.action()
end)
win.addChild(ctxmenu)
win.addChild(ctxmenubutton)


local function addApp(name, path)
    local btn = gui.button(0, #appcontainer.children, math.floor(w / 4), 1, name)
    btn.eventbus.on("click", function()
        local name = std.str.split(path, "/")[#std.str.split(path, "/")]
        local ok, err = pcall(process.load, name, path)
        if not ok then
            displayMsgBox("Opening failed!", err)
        end
    end)
    appcontainer.addChild(btn)
end

-- find everything in /bin that contains require("newgui")
local fs = require("fs")
printk("Loading apps")
local files = fs.list("/bin")
for file in files do
    printk("Checking " .. file)
    if fs.isDirectory("/bin/" .. file) then
    else
        local data = fs.open("/bin/" .. file, "r")
        local content = data:read(math.huge)
        data:close()
        if content:find("require%(\"newgui\"%)") then
            addApp(file, "/bin/" .. file)
        end
    end
end

gui.workspace.addChild(win)
