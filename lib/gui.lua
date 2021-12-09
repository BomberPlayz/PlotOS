local gui = {}
gui.click = false
gui.cx = 0
gui.cy = 0
gui.clickBlocked = false

gui.config = {
    WOWD = true
}

local buffering = require("doublebuffering")
local gpu = require("driver").load("gpu")
local event = require("event")

gui.event = event.emitter()

local keyboard = require("keyboard")

local codeMap = {
    space = " ",
    numpad0 = "0",
    numpad1 = "1",
    numpad2 = "2",
    numpad3 = "3",
    numpad4 = "4",
    numpad5 = "5",
    numpad6 = "6",
    numpad7 = "7",
    numpad8 = "8",
    numpad9 = "9",
    numpaddecimal = ".",
    equals = "=",
    apostrophe = "'",
    grave = "`"
}

local disabledCodeMap = {
    lshift = true,
    rshift = true,
    lcontrol = true,
    rcontrol = true,
    lmenu = true,
    rmenu = true,
    tab = true,
    numlock = true,
    scroll = true,
    pageUp = true,
    pageDown = true,
    insert = true,
    pause = true,
    f1 = true,
    f2 = true,
    f3 = true,
    f4 = true,
    f5 = true,
    f6 = true,
    f7 = true,
    f8 = true,
    f9 = true,
    f10 = true,
    f11 = true,
    f12 = true,
    f13 = true,
    f14 = true,
    f15 = true,
    f16 = true,
    f17 = true,
    f18 = true,
    f19 = true,
    f20 = true,
    f21 = true,
    f22 = true,
    f23 = true,
    f24 = true,
    up = true,
    down = true,
    left = true,
    right = true,
    home = true,
    ["end"] = true,
    delete = true
}

function gui.isObstructed(_, object)
    -- check if the object is obstructed by checking if coordinates overlap. If yes, return true, else return fals

    for _, obj in pairs(object.parent.children) do
        if
            obj ~= object and obj._parentIndex > object._parentIndex and obj.x <= object.x + object.width and
                obj.x + obj.width >= object.x and
                obj.y <= object.y + object.height and
                obj.y + obj.height >= object.y
         then
            return false
        end
    end
    return false
end

function gui.isObstructedAt(object, x, y)
    -- check if the object is obstructer by checking if coordinates overlap.

    for _, obj in pairs(object.parent.children) do
        if
            obj ~= object and obj._parentIndex > object._parentIndex and obj.x <= x and obj.x + obj.width >= x and
                obj.y <= y and
                obj.y + obj.height >= y
         then
            return false
        end
    end
    return false
end

local isObstructed = gui.isObstructed

gui.isInRect = function(x, y, w, h, px, py)
    --print("x: "..x.." y: "..y.." mx: "..x+w.." my: "..y+h.." mousex: "..gui.cx.." mousey: "..gui.cy)
    if px >= x and px <= x + w and py >= y and py <= y + h then
        --  print("ITTRUE")
        return true
    else
        return false
    end
end

gui.component = function()
    local obj = {}

    obj.x = 0
    obj.y = 0
    obj.width = 1
    obj.height = 1
    obj.dirty = true
    obj.visible = true

    function obj._draw(buf)
        error("Unimplemented draw method")
    end

    function obj._tick()
        if type(obj.tick) == "function" then
            obj.tick()
        else
            --print("TICCNONO")
        end
    end

    function obj.checkDirty()
    end

    function obj.isDirty()
        return obj.dirty
    end

    function obj.move(x, y)
        obj.x = x
        obj.y = y
        obj.dirty = true
    end

    obj._mousedown = function(x, y, btn)
        --print("mdown")
        if obj.onMouseDown then
            obj.onMouseDown(x, y, btn)
        end
    end

    obj._mouseup = function(x, y, btn)
        if obj.onMouseUp then
            obj.onMouseUp(x, y, btn)
        end
    end

    obj._drag = function(x, y)
        if obj.onDrag then
            obj.onDrag(x, y)
        end
    end

    return obj
end

gui.container = function(x, y, w, h)
    local obj = gui.component()
    obj.x = x
    obj.y = y
    obj.width = w
    obj.height = h
    obj.children = {}

    function obj:addChild(...)
        local children = table.pack(...)
        for i = 1, #children do
            children[i].parent = obj
            children[i]._parentIndex = #obj.children + 1
            table.insert(obj.children, children[i])
        end
    end

    obj._draw = function(buf)
        if not obj.visible then
            return
        end
        if not obj.visici then
        --buf.setBackground(0x000000)
        --buf.fill(obj.x,obj.y,obj.width,obj.height," ")
        end
        for k, v in ipairs(obj.children) do
            v.x = v.x + obj.x
            v.y = v.y + obj.y
            if v.dirty then
            end
            v._draw(buf)
            v.x = v.x - obj.x
            v.y = v.y - obj.y
        end
        obj.dirty = false
    end

    obj.checkDirty = function()
        local isDirt = false
        for k, v in ipairs(obj.children) do
            v.checkDirty()
            if v.dirty then
                isDirt = true
            end
        end
        obj.dirty = isDirt
    end

    obj._tick = function()
        if not obj.visible then
            return
        end
        if obj.tick then
            obj.tick()
        end
        for k = #obj.children, 1, -1 do
            local v = obj.children[k]
            v.x = v.x + obj.x
            v.y = v.y + obj.y
            v._tick()
            v.x = v.x - obj.x
            v.y = v.y - obj.y
        end
    end

    obj._mousedown = function(x, y, btn)
        if not obj.visible then
            return
        end
        --print("mdown")
        if obj.onMouseDown then
            obj.onMouseDown(x, y, btn)
        end

        for _, object in pairs(obj.children) do
            if object.visible then
                object.x = object.x + obj.x
                object.y = object.y + obj.y
                if
                    gui.cx >= object.x and gui.cx <= object.x + object.width and gui.cy >= object.y and
                        gui.cy <= object.y + object.height
                 then
                    obstructed = gui.isObstructedAt(object, gui.cx, gui.cy)
                    if not obstructed then
                        object._mousedown(gui.cx, gui.cy, btn)
                    end
                end
                object.x = object.x - obj.x
                object.y = object.y - obj.y
            end
        end
    end

    obj._mouseup = function(x, y, btn)
        if not obj.visible then
            return
        end
        if obj.onMouseUp then
            obj.onMouseUp(x, y, btn)
        end

        for _, object in pairs(obj.children) do
            if object.visible then
                object.x = object.x + obj.x
                object.y = object.y + obj.y
                if
                    gui.cx >= object.x and gui.cx <= object.x + object.width and gui.cy >= object.y and
                        gui.cy <= object.y + object.height
                 then
                    obstructed = gui.isObstructedAt(object, gui.cx, gui.cy)
                    if not obstructed then
                        object._mouseup(gui.cx, gui.cy, btn)
                    end
                end
                object.x = object.x - obj.x
                object.y = object.y - obj.y
            end
        end
    end

    obj._drag = function(x, y)
        if not obj.visible then
            return
        end
        if obj.onDrag then
            obj.onDrag(x, y)
        end

        for _, object in pairs(obj.children) do
            if object.visible then
                object.x = object.x + obj.x
                object.y = object.y + obj.y
                if
                    gui.cx >= object.x and gui.cx <= object.x + object.width and gui.cy >= object.y and
                        gui.cy <= object.y + object.height
                 then
                    obstructed = gui.isObstructedAt(object, gui.cx, gui.cy)
                    if not obstructed then
                        object._drag(gui.cx, gui.cy, btn)
                    end
                end
                object.x = object.x - obj.x
                object.y = object.y - obj.y
            end
        end
    end

    return obj
end

gui.text = function(x, y, text, fore, back)
    local obj = gui.component()
    obj.x = x
    obj.y = y
    obj.textColor = fore or 0xffffff
    obj.backColor = back or 0x000000
    obj.text = text
    obj.oldText = ""
    obj.width = string.len(text)

    obj._draw = function(buf)
        if not obj.visible then
            return
        end
        buf.setForeground(obj.textColor)
        buf.setBackground(obj.backColor)
        buf.set(obj.x, obj.y, obj.text)

        obj.dirty = false
    end

    obj.checkDirty = function()
        if obj.text ~= obj.oldText then
            obj.dirty = true
            obj.oldText = obj.text
        end
    end

    return obj
end

gui.textbox = function(x, y, w, h, charLimit, fore, back, selectedColor, cursorBgColor)
    local obj = gui.component()
    obj.dirty = true
    obj.x = x
    obj.y = y
    obj.width = w
    obj.height = h
    obj.textColor = fore or 0xffffff
    obj.backColor = back or 0x000000
    obj.selectedColor = selectedColor or 0x888888
    obj.cursorBgColor = cursorBgColor or 0x777777
    obj.charLimit = charLimit
    obj.text = ""
    obj.selected = false
    obj.enabled = true

    obj._draw = function(buf)
        local txtToSet = obj.text
        local bgColor = obj.backColor
        if obj.selected then
            bgColor = obj.selectedColor
        end
        buf.setForeground(obj.textColor)
        buf.setBackground(bgColor)
        buf.fill(obj.x, obj.y, obj.width, obj.height, " ")
        buf.set(obj.x, obj.y, obj.text)
        if obj.selected then
            if obj.enabled then
                if _G.cursorBlink then
                    buf.setBackground(obj.cursorBgColor)
                    buf.set(string.len(obj.text) + obj.x, obj.y, " ")
                end
            end
        end
        obj.dirty = false
    end

    local macska = function(a1, a2, key, a4, a5)
        if obj.selected then
            key = require("keyboard").keys[key]

            if key ~= nil then
                if key == "enter" then
                    obj.selected = false
                    gui.event.remove("key_down", macska)
                elseif key == "back" then
                    if obj.enabled then
                        if string.len(obj.text) > 0 then
                            obj.text = string.sub(obj.text, 1, string.len(obj.text) - 1)
                        end
                    end
                else
                    if obj.enabled then
                        if codeMap[key] ~= nil then
                            key = codeMap[key]
                        end
                        if disabledCodeMap[key] == nil then
                            if not (string.len(obj.text) >= obj.width) then
                                if not (string.len(obj.text) > obj.charLimit) then
                                    obj.text = obj.text .. key or ""
                                end
                            end
                        end
                    end
                end
                obj.dirty = true
            end
        end
    end

    obj.onSelected = function()
        gui.event.remove("key_down", macska)
        gui.event.on("key_down", macska)
    end

    obj.tick = function()
    end

    obj._mousedown = function(x, y, btn)
        if obj.enabled then
            obj.selected = true
            obj.onSelected()
        end
    end

    return obj
end

gui.panel = function(x, y, w, h, color)
    local obj = gui.component()
    obj.x = x
    obj.y = y
    obj.width = w
    obj.height = h
    obj.color = color or 0xffffff
    obj.dirty = true
    obj.opacity = 1
    obj._draw = function(buf)
        if not obj.visible then
            return
        end
        buf.setBackground(obj.color)
        buf.fill(obj.x, obj.y, obj.width, obj.height, " ", obj.opacity, obj.opacity)

        obj.dirty = false
    end

    return obj
end

gui.button = function(x, y, w, h, text)
    local obj = gui.component()
    local clickCooldown = 0
    obj.x = x
    obj.y = y
    obj.width = w
    obj.height = h
    obj.backColor = 0xCCCCCC
    obj.textColor = 0x000000

    obj.pbackColor = 0xA5A5A5
    obj.ptextColor = 0x000000

    obj.isPressed = false
    obj.dirty = true

    obj._draw = function(buf)
        if not obj.visible then
            return
        end
        buf.setForeground(obj.isPressed and obj.ptextColor or obj.textColor)
        buf.setBackground(obj.isPressed and obj.pbackColor or obj.backColor)
        buf.fill(obj.x, obj.y, obj.width, obj.height, " ")
        buf.set(obj.x, obj.y, text)
        obj.dirty = false
    end

    obj.onClick = function()
    end

    obj.tick = function()
        if not obj.visible then
            return
        end
        if obj.isPressed then
            obj.isPressed = false
            obj.dirty = true
            obj.onClick()
        end
    end
    -- migrate the above to the onMouseDown, and onDrop events.
    -- onMouseDown is triggered when the mouse gets pressed on the component, and onDrop is triggered when the mouse is released.
    -- The events are triggered on the component, and not on the parent.
    obj.onMouseDown = function(button)
        if not obj.visible then
            return
        end
        --print("THAT GHURTS STOP")
        obj.isPressed = true
        obj.dirty = true
    end

    obj.onMouseUp = function(button)
        if not obj.visible then
            return
        end
        obj.isPressed = false
        obj.dirty = true
    end

    return obj
end

gui.window = function(x, y, w, h, title)
    -- a simple window component. Should have a draggable titlebar, and a close button.
    local obj = gui.container(x, y, w, h)
    obj.title = title or "Untitled window"
    obj.titlebar = gui.container(0, 0, w, 1)
    obj.titlebar:addChild(gui.panel(0, 0, obj.titlebar.width, 1, 0xCCCCCC))
    obj.titlebar.children[1].opacity = 0.75
    local txt = gui.text(0, 0, obj.title)
    txt.backColor = 0xCCCCCC
    obj.titlebar:addChild(txt)

    local closeButton = gui.button(w - 1, 0, 1, 1, "X")
    closeButton.onClick = function()
        -- close the window
        --print("it be close")
        --error("YES")
        obj.close()
    end

    obj.close = function()
        -- window close logic
        local canClose = true
        if obj.onClose then
            if not obj.onClose() then
                canClose = false
            end
        end
        if canClose then
            gui.buffer.setBackground(0x000000)
            gui.buffer.fill(obj.x, obj.y, obj.width, obj.height, " ")
            table.remove(obj.parent.children, obj._parentIndex)
            for i = obj._parentIndex, #obj.parent.children do
                obj.parent.children[i]._parentIndex = i
            end
            obj.parent = nil
            obj._parentIndex = -1
            gui.buffer.draw()
        end
    end
    obj.titlebar:addChild(closeButton)

    obj:addChild(obj.titlebar)

    obj.container = gui.container(0, 1, w, h - 1)
    obj.container:addChild(gui.panel(0, 0, obj.container.width, obj.container.height, 0xffffff))
    obj:addChild(obj.container)
    obj.isDrag = false
    obj.drag = {sx = 0, sy = 0}

    obj.didMove = false

    obj.checkDirty = function()
        if obj.didMove then
            --  print("nived")
            obj.didMove = false
            obj.dirty = true
            return
        end

        local isDirt = false
        for k, v in ipairs(obj.children) do
            v.checkDirty()
            if v.dirty then
                isDirt = true
            end
        end
        obj.dirty = isDirt
    end

    function obj.redraw()
        if not obj.visible then
            return
        end
        obj.dirty = true
        function helper(obj)
            if obj.children then
                for k, v in ipairs(obj.children) do
                    helper(v)
                end
            else
                obj.dirty = true
            end
        end
        helper(obj)
    end

    function obj.tick()
        if not obj.visible then
            return
        end
        -- print("winticc")

        -- tick all child elements, like in a simple container, then handle drag logic.
        for k = #obj.children, 1, -1 do
            local v = obj.children[k]

            v._tick()
        end
    end

    function obj.titlebar.onMouseDown(button)
        if not obj.visible then
            return
        end
        obj.isDrag = true
        obj.drag.sx = gui.cx - obj.x
        obj.drag.sy = gui.cy - obj.y

        for _, object in pairs(obj.titlebar.children) do
            --print(tostring(object.x).."   y: "..object.y)
            if object.visible then
                object.x = object.x + obj.titlebar.x
                object.y = object.y + obj.titlebar.y
                if
                    gui.cx >= object.x and gui.cx <= object.x + object.width and gui.cy >= object.y and
                        gui.cy <= object.y + object.height
                 then
                    obstructed = gui.isObstructedAt(object, gui.cx, gui.cy)
                    if not obstructed then
                        object._mousedown(gui.cx, gui.cy, btn)
                    end
                end
                object.x = object.x - obj.titlebar.x
                object.y = object.y - obj.titlebar.y
            end
        end
    end

    function obj.titlebar.onMouseUp(button)
        if not obj.visible then
            return
        end
        obj.isDrag = false

        for _, object in pairs(obj.titlebar.children) do
            if object.visible then
                object.x = object.x + obj.titlebar.x
                object.y = object.y + obj.titlebar.y
                if
                    gui.cx >= object.x and gui.cx <= object.x + object.width and gui.cy >= object.y and
                        gui.cy <= object.y + object.height
                 then
                    obstructed = gui.isObstructedAt(object, gui.cx, gui.cy)
                    if not obstructed then
                        object._mouseup(gui.cx, gui.cy, btn)
                    end
                end
                object.x = object.x - obj.titlebar.x
                object.y = object.y - obj.titlebar.y
            end
        end
    end

    function obj.titlebar.onDrag()
        if not obj.visible then
            return
        end

        for _, object in pairs(obj.titlebar.children) do
            if object.visible then
                object.x = object.x + obj.titlebar.x
                object.y = object.y + obj.titlebar.y
                if
                    gui.cx >= object.x and gui.cx <= object.x + object.width and gui.cy >= object.y and
                        gui.cy <= object.y + object.height
                 then
                    obstructed = gui.isObstructedAt(object, gui.cx, gui.cy)
                    if not obstructed then
                        object._drag(gui.cx, gui.cy, btn)
                    end
                end
                object.x = object.x - obj.titlebar.x
                object.y = object.y - obj.titlebar.y
            end
        end
    end

    function obj.titlebar.tick()
        if not obj.visible then
            return
        end
        for k = #obj.titlebar.children, 1, -1 do
            local v = obj.titlebar.children[k]

            v._tick()
        end
        if obj.isDrag and not gui.isObstructedAt(obj, gui.cx, gui.cy) then
            obj.x = gui.cx - obj.drag.sx
            obj.y = gui.cy - obj.drag.sy
            obj.didMove = true
            obj.redraw()
        else
            if gui.isObstructedAt(obj, gui.cx, gui.cy) then
                obj.didMove = false
                obj.isDrag = false
            end
        end
    end

    -- migrate the above to the onMouseDown, onDrop, and onDrag events.
    function obj.onMouseDown(button)
        if not obj.visible then
            return
        end
        local obstructed = false
        for _, object in pairs(obj.children) do
            if object.visible then
                object.x = object.x + obj.x
                object.y = object.y + obj.y
                if
                    gui.cx >= object.x and gui.cx <= object.x + object.width and gui.cy >= object.y and
                        gui.cy <= object.y + object.height
                 then
                    obstructed = gui.isObstructedAt(object, gui.cx, gui.cy)
                    if not obstructed then
                        object._mousedown(gui.cx, gui.cy, btn)
                    end
                end
                object.x = object.x - obj.x
                object.y = object.y - obj.y
            end
        end

        if
            gui.cx >= obj.titlebar.x and gui.cx <= obj.titlebar.x + obj.titlebar.width and gui.cy >= obj.titlebar.y and
                gui.cy <= obj.titlebar.y + obj.titlebar.height and
                not gui.isObstructedAt(obj.titlebar, gui.cx, gui.cy)
         then
            obj.titlebar._mousedown(button)
        end

        if
            gui.cx >= obj.container.x and gui.cx <= obj.container.x + obj.container.width and gui.cy >= obj.container.y and
                gui.cy <= obj.container.y + obj.container.height and
                not gui.isObstructedAt(obj.container, gui.cx, gui.cy)
         then
            obj.container._mousedown(button)
        end
    end

    function obj.onMouseUp(btn)
        if not obj.visible then
            return
        end
        local obstructed = false
        for _, object in pairs(obj.children) do
            if object.visible then
                object.x = object.x + obj.x
                object.y = object.y + obj.y
                if
                    gui.cx >= object.x and gui.cx <= object.x + object.width and gui.cy >= object.y and
                        gui.cy <= object.y + object.height
                 then
                    obstructed = isObstructed(obj, object)
                    if not obstructed then
                        object._mouseup(gui.cx, gui.cy, btn)
                    end
                end
                object.x = object.x - obj.x
                object.y = object.y - obj.y
            end
        end
        if
            gui.cx >= obj.titlebar.x and gui.cx <= obj.titlebar.x + obj.titlebar.width and gui.cy >= obj.titlebar.y and
                gui.cy <= obj.titlebar.y + obj.titlebar.height and
                not gui.isObstructedAt(obj.titlebar, gui.cx, gui.cy)
         then
            obj.titlebar._mouseup(btn)
        end

        if
            gui.cx >= obj.container.x and gui.cx <= obj.container.x + obj.container.width and gui.cy >= obj.container.y and
                gui.cy <= obj.container.y + obj.container.height and
                not gui.isObstructedAt(obj.container, gui.cx, gui.cy)
         then
            obj.container._mouseup(btn)
        end
    end

    function obj.onDrag()
        if not obj.visible then
            return
        end
        local obstructed = false
        for _, object in pairs(obj.children) do
            if object.visible then
                object.x = object.x + obj.x
                object.y = object.y + obj.y
                if
                    gui.cx >= object.x and gui.cx <= object.x + object.width and gui.cy >= object.y and
                        gui.cy <= object.y + object.height
                 then
                    obstructed = isObstructed(obj, object)
                    if not obstructed then
                        object._drag(gui.cx, gui.cy, btn)
                    end
                end
                object.x = object.x - obj.x
                object.y = object.y - obj.y
            end
        end
        -- drag titlebar if in bounds of it
        if
            gui.cx >= obj.titlebar.x and gui.cx <= obj.titlebar.x + obj.titlebar.width and gui.cy >= obj.titlebar.y and
                gui.cy <= obj.titlebar.y + obj.titlebar.height and
                not gui.isObstructedAt(obj.titlebar, gui.cx, gui.cy)
         then
            obj.titlebar._drag(gui.cx, gui.cy, btn)
        end

        if
            gui.cx >= obj.container.x and gui.cx <= obj.container.x + obj.container.width and gui.cy >= obj.container.y and
                gui.cy <= obj.container.y + obj.container.height and
                not gui.isObstructedAt(obj.container, gui.cx, gui.cy)
         then
            obj.container._drag(gui.cx, gui.cy, btn)
        end

        obj.redraw()
    end

    function obj:addChild(child)
        return obj.container:addChild(child)
    end

    return obj
end

gui.progressBar = function(x, y, w, h)
    local obj = gui.container(x, y, w, h)
    obj.type = "progressBar"
    obj.value = 0
    obj.max = 100
    obj.fillColor = 0x5aff5a
    obj.emptyColor = 0xdddddd

    obj._draw = function()
        if not obj.visible then
            return
        end
        gui.buffer.setBackground(obj.emptyColor)
        gui.buffer.fill(obj.x, obj.y, obj.width, obj.height, " ")
        gui.buffer.setBackground(obj.fillColor)
        gui.buffer.fill(obj.x, obj.y, obj.width * obj.value / obj.max, obj.height, " ")
    end
    return obj
end

gui.progressBarVertical = function(x, y, w, h)
    local obj = gui.container(x, y, w, h)
    obj.type = "progressBarVertical"
    obj.value = 0
    obj.max = 100
    obj.fillColor = 0x5aff5a
    obj.emptyColor = 0xdddddd

    obj._draw = function()
        if not obj.visible then
            return
        end
        gui.buffer.setBackground(obj.fillColor)
        gui.buffer.fill(obj.x, obj.y, obj.width, obj.height, " ")
        gui.buffer.setBackground(obj.emptyColor)
        gui.buffer.fill(obj.x, obj.y, obj.width, obj.height - (obj.height * obj.value / obj.max), " ")
    end
    return obj
end

gui.buffer = buffering.getMain()

gui.workspace = gui.container(0, 0, gui.buffer.getResolution())
gui.workspace.tick = function()
    gui.workspace.checkDirty()
    if gui.workspace.dirty then
        gui.buffer.setBackground(0x000000)
        local rw, rh = gui.buffer.getResolution()
        gui.buffer.fill(1, 1, rw, rh, " ")
        gui.workspace._draw(gui.buffer)
        gui.buffer.draw()
    end
end
gui.rootObject = gui.workspace

require("process").new(
    "GuiTicker",
    [[
    local gui = require("gui")
    local event = require("event")

    event.listen("touch",function(event,_,x,y,btn)
    --   print(event)
    -- print("touch")
    gui.click = true
    -- print(tostring(gui.click))
    gui.cx = x
    gui.cy = y
    -- check the first object that collides with the touch
    local obstructed = false
    for _, object in pairs(gui.rootObject.children) do
        -- check if touch x and y is in side the object
        if object.visible and x >= object.x and x <= object.x + object.width and y >= object.y and y <= object.y + object.height then
            -- check if the object is obstructed by another object in rootObject.
            if not gui.isObstructed(gui.rootObject, object) then
                object._mousedown(x - object.x, y - object.y, btn)
                obstructed = true
                break
            end
        end

    end














end)

event.listen("drag",function(event,_,x,y,btn)


    gui.cx = x
    gui.cy = y
    local obstructed = false
    for _, object in pairs(gui.rootObject.children) do
        if object.visible and x >= object.x and x <= object.x + object.width and y >= object.y and y <= object.y + object.height then
            -- check if the object is obstructed by another object in rootObject.
            if not gui.isObstructed(gui.rootObject, object) then
                object._drag(x - object.x, y - object.y, btn)
                obstructed = true
                break
            end
        end
    end


end)

event.listen("drop",function(event,_,x,y,btn)
    gui.click = false

    gui.cx = x
    gui.cy = y
    local obstructed = false
    for _, object in pairs(gui.rootObject.children) do
        if object.visible and x >= object.x and x <= object.x + object.width and y >= object.y and y <= object.y + object.height then
            -- check if the object is obstructed by another object in rootObject.
            if not gui.isObstructed(gui.rootObject, object) then
                object._mouseup(x - object.x, y - object.y, btn)
                obstructed = true
                break
            end
        end
    end




end)

    while true do
        local e = {computer.pullSignal(0)}
        if e[1] == "key_down" then
            gui.event.emit("key_down",e[2],e[3],e[4],e[5])
        end
        gui.workspace._tick()
    end
]],
    nil,
    true
)

return gui
