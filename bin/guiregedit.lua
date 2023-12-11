local gui = require("newgui")
local reg = require("registry")
local gpu = require("driver").load("gpu")

local w,h = gpu.getResolution()
local window = gui.window(10,10,75,35)
window.content.color = 0xcccccc

local function createTree(parent, path)
    local keys = reg.list(path)
    for key, value in pairs(keys) do
        local node = gui.treeNode(key)
        parent.addChild(node)
        if type(value) == "table" then
            createTree(node, path .. "/" .. key)
        else
            node.addChild(gui.treeNode(tostring(value)))
        end
    end
end

local root = gui.treeNode("Root")
createTree(root, "/")
window.addChild(root)

gui.workspace.addChild(window)