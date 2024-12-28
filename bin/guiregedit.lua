local gui = require("newgui")
local reg = require("registry")
local gpu = require("driver").load("gpu")

local w,h = gpu.getResolution()
local window = gui.window(10,10,75,35)
window.content.color = 0xcccccc

local function createTree(parent, path)
    local keys = reg.list(path)
    local i=0
    for key, value in pairs(keys) do
        i = i+1
        printk(key)
        printk(value)
        local node = gui.treeNode(key, 1, i)
        parent.addChild(node)
        --[[if type(value) == "table" then
            createTree(node, path .. "/" .. key)
        else
            node.addChild(gui.treeNode(tostring(value)))
        end]]
        if value == reg.types.collection then
            printk("ITS A COLLECITON YO")
            createTree(node, path .. "/" .. key)
        else
            node.addChild(gui.treeNode(tostring(value)))
        end
    end
end

local root = gui.treeNode("Root", 0, 0)
createTree(root, "/system")
window.addChild(root)

gui.workspace.addChild(window)