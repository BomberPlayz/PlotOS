local dbuf = require("doublebuffering")
local reg = require("registry")
local gpu = require("driver").load("gpu")
local keyboard = require("keyboard")


local buffer = gpu
buffer.width, buffer.height = buffer.getResolution()


buffer.setBackground(0x000000)
buffer.fill(1, 1, buffer.width, buffer.height, " ")
print(buffer.width, buffer.height)
-- buffer.draw()

function EventEmitter()
    local self = {}
    local listeners = {}

    self.on = function(event, callback)
        if not listeners[event] then
            listeners[event] = {}
        end
        table.insert(listeners[event], callback)
    end

    self.emit = function(event, ...)
        if listeners[event] then
            for _, callback in ipairs(listeners[event]) do
                callback(...)
            end
        end
    end

    return self
end

local function getParentAttrib(attrib, obj)
    if obj.parent then
        if obj.parent[attrib] then
            return obj.parent[attrib]
        else
            return getParentAttrib(attrib, obj.parent)
        end
    else
        return nil
    end
end


local gui = {}
gui.buffer = buffer
gui.requestedDraws = {}
gui.focused = nil


function gui.component(x, y, w, h)
    local comp = {}
    comp.x = x
    comp.y = y
    comp.w = w
    comp.h = h
    comp.backgroundColor = 0xffffff
    comp.foregroundColor = 0x000000
    comp.draw_shadow = false

    comp._gx = 0
    comp._gy = 0

    comp.draw = function() end
    comp.beforeDraw = function() end
    comp.afterDraw = function() end
    comp.onEvent = function() end

    -- set a metatable for beforedraw so when it is called, it first sets the buffer (gpu) to its own buffer (or create one)
    --comp.buffer = buffer.allocateBuffer(comp.w, comp.h)
    local lastbuf = buffer.getActiveBuffer()

    comp._beforeDraw = function()

    end

    comp._afterDraw = function()

    end

    -- when the component size changes, the buffer should be resized as well
    setmetatable(comp, {
        __newindex = function(t, k, v)
            if k == "w" or k == "h" then
                -- free the buffer
                gpu.freeBuffer(comp.buffer)
                -- create a new buffer
                comp.buffer = gpu.allocateBuffer(comp.w, comp.h)
            end
            if k == "dirty" then
                if comp.parent then
                    comp.parent.dirty = v
                end
            end
            rawset(t, k, v)
        end
    })

    comp.dirty = true

    comp.parent = nil

    comp.enabled = true

    comp.eventbus = EventEmitter()

    comp.setDirty = function()
        comp.dirty = true
    end

    comp.requestedDraws = {}


    -- requests a draw in a specified area.
    comp.requestDraw = function(x, y, w, h)
        -- check if requestedDraws doesnt have an entry for this x y w h
        local found = false
        for _, v in ipairs(comp.requestedDraws) do
            if v[1] == x and v[2] == y and v[3] == w and v[4] == h then
                found = true
                break
            end
        end
        if not found then
            table.insert(comp.requestedDraws, { x, y, w, h })
        end
    end

    comp._update = function()
    end

    comp.update = function()
    end

    return comp
end

function gui.container(x, y, w, h)
    local cont = gui.component(x, y, w, h)
    cont.children = {}
    cont.alwaysDraw = true -- TODO: fix not drawing stuff until needed

    cont.draw = function(special)
        buffer.setMask(cont.x, cont.y, cont.w, cont.h)



        for _, child in ipairs(cont.children) do
            -- check if the child is not obscured by another child. The other child should have a higher index in the table.
            -- check from the root object. --

            if child.enabled then
                child.x = child.x + cont.x
                child.y = child.y + cont.y

                if child.dirty or cont.alwaysDraw then
                    child._beforeDraw()
                    child.beforeDraw()
                    child.draw(special)
                    child.afterDraw()
                    child._afterDraw()
                    if child.draw_shadow and child.enabled then
                        -- draw two black lines around the component
                        local mask = { buffer.getMask() }
                        buffer.setMask(0, 0, buffer.width, buffer.height)
                        buffer.setForeground(0x000000)
                        --[[for i = 1, child.w do
                            buffer.set(child.x + i, child.y + child.h, "█")
                        end
                        for i = 0, child.h do
                            buffer.set(child.x + child.w, child.y + i, "█")
                        end]]
                        buffer.fill(child.x + 1, child.y + child.h, child.w - 1, 1, "█")
                        buffer.fill(child.x + child.w, child.y + 1, 1, child.h, "█")
                        buffer.setMask(table.unpack(mask))
                    end

                    child.dirty = false
                end

                child.x = child.x - cont.x
                child.y = child.y - cont.y
            end
        end







        buffer.setMask(0, 0, buffer.width, buffer.height)
    end



    cont.onEvent = function(event)
        -- loop in an inverse order and check if the event has an x and y. If so then when a child gets the event, it won't propogate further.
        for i = #cont.children, 1, -1 do
            local child = cont.children[i]
            if child.enabled then
                if event.x and event.y and event.x >= child._gx and event.x < child._gx + child.w and event.y >= child._gy and event.y < child._gy + child.h then
                    child.x = cont.x + child.x
                    child.y = cont.y + child.y

                    gui.focused = child

                    child.onEvent(event)
                    child.x = child.x - cont.x
                    child.y = child.y - cont.y
                    return
                else
                    if not (event.x and event.y) then
                        child.x = cont.x + child.x
                        child.y = cont.y + child.y

                        child.onEvent(event)
                        child.x = child.x - cont.x
                        child.y = child.y - cont.y
                    end
                end
                if child.dirty then
                    cont.dirty = true
                end
            end
        end
    end

    cont._update = function()
        for _, child in ipairs(cont.children) do
            if child.enabled then
                child._gx = child.x + cont._gx
                child._gy = child.y + cont._gy
            end
        end
    end

    cont.update = function()
        for _, child in ipairs(cont.children) do
            if child.enabled then
                child._update()
                child.update()
            end
        end
    end





    cont.addChild = function(child)
        child.parent = cont
        child.backgroundColor = cont.backgroundColor
        child.foregroundColor = cont.foregroundColor
        table.insert(cont.children, child)
        cont.dirty = true
    end

    cont.removeChild = function(child)
        for i, c in ipairs(cont.children) do
            if c == child then
                table.remove(cont.children, i)
                break
            end
        end
        cont.dirty = true
    end

    cont.setDirty = function()
        cont.dirty = true
        for _, child in ipairs(cont.children) do
            child.setDirty()
        end
    end

    return cont
end

function gui.button(x, y, w, h, text)
    local btn = gui.component(x, y, w, h)
    btn.text = text

    btn.clicked = false
    btn.clickTick = false

    btn.backgroundColor = 0xaaaaaa


    btn.draw = function()
        -- kern_info("drawing button at "..tostring(btn.x)..", "..tostring(btn.y))
        -- if the button is clicked then the color is a bit darker so subtract

        if btn.clicked then
            buffer.setForeground(btn.foregroundColor)
            buffer.setBackground(btn.backgroundColor - 0x111111)

            btn.clicked = false
            btn.dirty = true
        else
            buffer.setForeground(btn.foregroundColor)
            buffer.setBackground(btn.backgroundColor)
        end

        buffer.fill(btn.x, btn.y, btn.w, btn.h, " ")
        -- center the text
        buffer.set(btn.x + math.floor(btn.w / 2) - math.floor(#btn.text / 2), btn.y + math.floor(btn.h / 2), btn.text)
    end

    btn.onEvent = function(event)
        if event.type == "touch" then
            btn.clicked = true

            btn.eventbus.emit("click", { x = event.x - btn.x, y = event.y - btn.y })

            btn.dirty = true
        end
    end

    return btn
end

function gui.label(x, y, w, h, text)
    local lbl = gui.component(x, y, w, h)
    lbl.text = text

    lbl.color = 0xffffff
    lbl.background = nil

    lbl.draw = function()
        buffer.setForeground(lbl.color)
        -- if we have a parent set our bg to the parent's bg
        if getParentAttrib("color", lbl) then
            buffer.setBackground(getParentAttrib("color", lbl) or lbl.parent.color)
        else
            buffer.setBackground(lbl.background or 0x000000)
        end
        buffer.fill(lbl.x, lbl.y, lbl.w, lbl.h, " ")
        -- split the text by newlines
        local lines = {}
        for line in lbl.text:gmatch("[^\n]+") do
            table.insert(lines, line)
        end

        if #lines < 1 then
            table.insert(lines, lbl.text)
        end

        for i, line in ipairs(lines) do
            buffer.set(lbl.x, lbl.y + i - 1, line)
        end
    end

    return lbl
end

function gui.panel(x, y, w, h, color, char)
    local pnl = gui.container(x, y, w, h)

    pnl.color = color or 0xaaaaaa
    pnl.char = char or " "


    pnl.draw = function(special)
        buffer.setBackground(pnl.color)
        buffer.fill(pnl.x, pnl.y, pnl.w, pnl.h, pnl.char)

        buffer.setMask(pnl.x, pnl.y, pnl.w, pnl.h)



        for _, child in ipairs(pnl.children) do
            -- check if the child is not obscured by another child. The other child should have a higher index in the table.
            -- check from the root object.

            if child.enabled then
                child.x = child.x + pnl.x
                child.y = child.y + pnl.y


                if child.dirty or pnl.alwaysDraw then
                    child._beforeDraw()
                    child.beforeDraw()
                    child.draw(special)
                    child.afterDraw()
                    child._afterDraw()
                    if child.draw_shadow and child.enabled then
                        -- draw two black lines around the component
                        local mask = { buffer.getMask() }
                        buffer.setMask(0, 0, buffer.width, buffer.height)
                        buffer.setForeground(0x000000)
                        buffer.fill(child.x + 1, child.y + child.h, child.w - 1, 1, "█")
                        buffer.fill(child.x + child.w, child.y + 1, 1, child.h, "█")
                        buffer.setMask(table.unpack(mask))
                    end
                    child.dirty = false
                end

                child.x = child.x - pnl.x
                child.y = child.y - pnl.y
            end
        end





        buffer.setMask()
    end

    return pnl
end

function gui.progressBar(x, y, w, h, max)
    local bar = gui.component(x, y, w, h)

    -- if the progress is -1 then it is indeterminate. In case of indeterminate progress, the bar will have an animation of a moving line bouncing back and forth.
    bar.progress = 0

    bar.setProgress = function(progress)
        if not progress then error("progress cannot be nil") end
        bar.progress = progress
        bar.dirty = true
    end

    local animation = 0
    local animDir = 1

    bar.color = 0xaaaaaa
    bar.progressColor = 0x2b8a16

    bar.intdeterminateBarSize = 4

    bar.max = max

    bar.draw = function(special)
        if bar.progress == -1 then
            buffer.setBackground(bar.color)
            buffer.fill(bar.x, bar.y, bar.w, bar.h, " ")

            buffer.setBackground(bar.progressColor)
            -- take indeterminate barsize into account
            buffer.fill(bar.x + animation, bar.y, bar.intdeterminateBarSize, bar.h, " ")




            animation = animation + animDir
            if animation + bar.intdeterminateBarSize >= bar.w then
                animDir = -1
            elseif animation == 0 then
                animDir = 1
            end
            bar.dirty = true
        else
            buffer.setBackground(bar.color)
            buffer.fill(bar.x, bar.y, bar.w, bar.h, " ")

            buffer.setBackground(bar.progressColor)
            buffer.fill(bar.x, bar.y, math.floor(bar.progress / bar.max * bar.w), bar.h, " ")
        end
    end

    return bar
end

--- Creates a new window
--- @param x number
--- @param y number
--- @param w number
--- @param h number
--- @param options? { title: string }
function gui.window(x, y, w, h, options)
    local win = gui.container(x, y, w, h)

    local titlebar_color = reg.get("system/ui/window/titlebar_color")
    local titleBar = gui.panel(0, 0, w, 1, titlebar_color)
    local title = gui.label(0, 0, w, 1, options and options.title or "Window")
    local closeButton = gui.button(w - 1, 0, 1, 1, "x")
    -- check if we have enough vram
    if gpu.freeMemory() < w * h then
        return nil, "Not enough VRAM"
    end
    win.buffer = gpu.allocateBuffer(w, h)
    win.draw_shadow = reg.get("system/ui/window/shadow_always") == 1
    win.always_shadow = reg.get("system/ui/window/shadow_always") == 1
    win.shadow_on_drag = reg.get("system/ui/window/shadow_on_drag") == 1
    win.drag_borders = reg.get("system/ui/window/drag_borders") == 1


    titleBar.addChild(title)
    titleBar.addChild(closeButton)

    win.addChild(titleBar)
    win.titlebar = titleBar

    local con = gui.container(0, 0, win.w, win.h)
    con.addChild(gui.panel(0, 1, 1, win.h - 1, 0xffffff, "░"))
    con.addChild(gui.panel(1, win.h - 1, win.w - 1, 1, 0xffffff, "░"))
    con.addChild(gui.panel(win.w - 1, 1, 1, win.h - 1, 0xffffff, "░"))
    win.addChild(con)
    con.enabled = false

    win.title = title
    win.closeButton = closeButton

    win.lastX = x
    win.lastY = y

    win.isClosed = false

    win.close = function()
        win.eventbus.emit("close")

        -- clean up the buffer
        gpu.freeBuffer(win.buffer)

        -- remove the window from the parent
        win.parent.removeChild(win)
        win.isClosed = true
    end

    closeButton.eventbus.on("click", function()
        win.close()
    end)

    local content = gui.panel(0, 1, w, h - 1)
    win.addChild(content)
    win.content = content

    win.addChild = function(child)
        content.addChild(child)
    end

    win.removeChild = function(child)
        content.removeChild(child)
    end

    win.doRequestMove = false

    titleBar.onEvent = function(event)
        if event.type == "touch" then
            win.dragging = true
            win.dragX = event.x
            win.dragY = event.y
            win.dragOffsetX = win.x - event.x
            win.dragOffsetY = win.y - event.y
            if win.shadow_on_drag then
                win.draw_shadow = true
            end
            if win.drag_bordersq then
                content.enabled = false
                con.enabled = true
            end
        elseif event.type == "drag" then
            if win.dragging then
                win.lastX = win.x
                win.lastY = win.y
                win.doRequestMove = true

                win.x = event._x + win.dragOffsetX
                win.y = event._y + win.dragOffsetY
                titleBar.x = event._x + win.dragOffsetX
                titleBar.y = event._y + win.dragOffsetY
                --print(win.x, win.y)
                win.setDirty()
            end
        elseif event.type == "drop" then
            win.dragging = false
            if win.shadow_on_drag and not win.always_shadow then
                win.draw_shadow = false
            end
            if win.drag_borders then
                content.enabled = true
                con.enabled = false
            end
        end

        for i = #titleBar.children, 1, -1 do
            local child = titleBar.children[i]
            if child.enabled then
                if event.x and event.y and event.x >= child._gx and event.x < child._gx + child.w and event.y >= child._gy and event.y < child._gy + child.h then
                    child.x = titleBar.x + child.x
                    child.y = titleBar.y + child.y

                    child.onEvent(event)
                    child.x = child.x - titleBar.x
                    child.y = child.y - titleBar.y
                    return
                else
                    if not (event.x and event.y) then
                        child.x = titleBar.x + child.x
                        child.y = titleBar.y + child.y
                        child.onEvent(event)
                        child.x = child.x - titleBar.x
                        child.y = child.y - titleBar.y
                    else
                    end
                end
                if child.dirty then
                    win.dirty = true
                end
            end
        end
    end

    win.onEvent = function(event)
        if event.type == "touch" then
            -- we are more important; get ourselves to the front
            local ourindex = -1
            for i = 1, #win.parent.children do
                if win.parent.children[i] == win then
                    ourindex = i
                    break
                end
            end
            if ourindex ~= #win.parent.children then
                table.remove(win.parent.children, ourindex)
                table.insert(win.parent.children, win)
            end
        end
        for i = #win.children, 1, -1 do
            local child = win.children[i]
            if child.enabled then
                if event.x and event.y and event.x >= child._gx and event.x < child._gx + child.w and event.y >= child._gy and event.y < child._gy + child.h then
                    child.x = win.x + child.x
                    child.y = win.y + child.y

                    child.onEvent(event)
                    child.x = child.x - win.x
                    child.y = child.y - win.y
                    return
                else
                    if not (event.x and event.y) then
                        child.x = win.x + child.x
                        child.y = win.y + child.y
                        child.onEvent(event)
                        child.x = child.x - win.x
                        child.y = child.y - win.y
                    end
                end
                if child.dirty then
                    win.dirty = true
                end
            end
        end
    end

    win.lastbuf = buffer.getActiveBuffer()

    win._beforeDraw = function()
        win.lastbuf = buffer.getActiveBuffer()
        buffer.setActiveBuffer(win.buffer)
    end

    win._afterDraw = function()
        buffer.bitblt(win.lastbuf, win.x, win.y, win.w, win.h, win.buffer, 1, 1)
        buffer.setActiveBuffer(win.lastbuf)
    end



    win.draw = function(special)
        for i, child in ipairs(win.children) do
            if child.enabled then
                child.x = child.x + 1
                child.y = child.y + 1


                if child.dirty or win.alwaysDraw then
                    child._beforeDraw()
                    child.beforeDraw()
                    child.draw(special)
                    child.afterDraw()
                    child._afterDraw()
                    if child.draw_shadow and child.enabled then
                        -- draw two black lines around the component
                        local mask = { buffer.getMask() }
                        buffer.setMask(0, 0, buffer.width, buffer.height)
                        buffer.setForeground(0x000000)
                        buffer.fill(child.x + 1, child.y + child.h, child.w - 1, 1, "█")
                        buffer.fill(child.x + child.w, child.y + 1, 1, child.h, "█")
                        buffer.setMask(table.unpack(mask))
                    end

                    child.dirty = false
                end

                child.x = child.x - 1
                child.y = child.y - 1
            end
        end
    end

    win.setTitle = function(title)
        win.title.text = title
        win.title.setDirty()
    end




    return win
end

function gui.treeNode(text)
    local node = gui.container(0, 0, 0, 0)
    node.text = text

    node.expanded = false

    node.color = 0xaaaaaa
    node.foreColor = 0x000000

    node.draw = function()
        buffer.setForeground(node.foreColor)
        buffer.setBackground(node.color)
        buffer.fill(node.x, node.y, node.w, node.h, " ")

        buffer.set(node.x, node.y, node.text)
    end

    node.onEvent = function(event)
        if event.type == "touch" then
            node.expanded = not node.expanded
            node.dirty = true
        end
    end

    return node
end

function gui.textinput(x, y, w, h)
    local textinput = gui.component(x, y, w, h)
    textinput.text = ""
    textinput.cursor = true
    textinput.cursorX = 0
    textinput.cursorY = 0

    textinput.cameraX = 0

    textinput.draw = function()
        -- set the camera x so that if the cursor is off the screen, the textinput will scroll
        local cursorCamDelta = textinput.cursorX - textinput.cameraX
        if cursorCamDelta < 0 then
            textinput.cameraX = textinput.cursorX
        elseif cursorCamDelta > textinput.w - 1 then
            textinput.cameraX = textinput.cursorX - textinput.w + 1
        end

        local cutText = textinput.text:sub(textinput.cameraX + 1, textinput.cameraX + textinput.w)

        buffer.setForeground(textinput.foregroundColor)
        buffer.setBackground(textinput.backgroundColor)
        buffer.fill(textinput.x, textinput.y, textinput.w, textinput.h, " ")
        buffer.set(textinput.x, textinput.y, cutText)
        if textinput.cursor and gui.focused == textinput then
            -- inver the foreground and background colors at the cursor position
            local oldfg = buffer.getForeground()
            local oldbg = buffer.getBackground()
            buffer.setForeground(oldbg)
            buffer.setBackground(oldfg)
            local cutCursor = textinput.cursorX - textinput.cameraX
            --buffer.set(textinput.x + textinput.cursorX, textinput.y + textinput.cursorY,
            --    buffer.get(textinput.x + textinput.cursorX, textinput.y + textinput.cursorY))
            buffer.set(textinput.x + cutCursor, textinput.y, buffer.get(textinput.x + cutCursor, textinput.y))

            buffer.setForeground(oldfg)
            buffer.setBackground(oldbg)
        end
    end


    textinput.onEvent = function(event)
        if event.type == "key_down" and gui.focused == textinput then
            -- if the key is enter
            if event.key == 13 then
                -- deselect the textinput
                textinput.focused = false
                gui.focused = nil
                return
                -- if the key is backspace
            elseif event.key == 8 and textinput.cursorX > 0 then
                -- remove the last character from the text at the cursor
                textinput.text = textinput.text:sub(1, textinput.cursorX - 1) ..
                    textinput.text:sub(textinput.cursorX + 1)
                textinput.dirty = true
                textinput.cursorX = textinput.cursorX - 1
                -- if the key is a printable character
                -- arrow right
            elseif event.keycode == 205 and textinput.cursorX < #textinput.text then
                textinput.cursorX = textinput.cursorX + 1
                textinput.dirty = true
                -- arrow left
            elseif event.keycode == 203 and textinput.cursorX > 0 then
                textinput.cursorX = textinput.cursorX - 1
                textinput.dirty = true
            elseif event.key > 31 and event.key < 127 then
                -- add the character to the cursor
                local char = string.char(event.key)
                textinput.text = textinput.text:sub(1, textinput.cursorX) ..
                    char .. textinput.text:sub(textinput.cursorX + 1)
                textinput.cursorX = textinput.cursorX + 1
                textinput.dirty = true
            end
            textinput.dirty = true
        end
    end

    return textinput
end

function gui.contextmenu(items)
    local contextmenu = gui.container(0, 0, 0, 0)
    contextmenu.eventbus = EventEmitter()
    contextmenu.enabled = false
    contextmenu.items = items
    contextmenu.draw_shadow = true
    function contextmenu.updateItems()
        local itemc = 0
        local longestitem = 0
        for i, item in ipairs(contextmenu.items) do
            itemc = itemc + 1
            if #item.text > longestitem then
                longestitem = #item.text
            end
        end
        while #contextmenu.children > 0 do
            contextmenu.removeChild(contextmenu.children[1])
        end
        for i, item in ipairs(contextmenu.items) do
            local itemobj = gui.button(0, itemc - 1, longestitem, 1, item.text)
            itemobj.backgroundColor = 0xffffff
            itemobj.eventbus.on("click", function()
                contextmenu.eventbus.emit("item_click", item)
                contextmenu.enabled = false
                contextmenu.dirty = true
            end
            )

            contextmenu.addChild(itemobj)
        end
        contextmenu.h = itemc
        contextmenu.w = longestitem
    end

    function contextmenu.showAt(x, y)
        contextmenu.updateItems()
        contextmenu.x = x
        contextmenu.y = y
        contextmenu.enabled = true
        contextmenu.parent.dirty = true
    end

    local alreadyfucked = false
    function contextmenu.update()
        alreadyfucked = true
        -- the context menu feels that it is important so it places itself on top
        -- find ourselves in parent
        local cont = contextmenu.parent
        for ae, child in ipairs(cont.children) do
            if child == contextmenu then
                table.remove(cont.children, ae)
                table.insert(cont.children, contextmenu)
                contextmenu.dirty = true
                break
            end
        end

        for _, child in ipairs(contextmenu.children) do
            if child.enabled then
                child._update()
                child.update()
            end
        end
    end

    function contextmenu._update()
        alreadyfucked = false
        for _, child in ipairs(contextmenu.children) do
            if child.enabled then
                child._gx = child.x + contextmenu._gx
                child._gy = child.y + contextmenu._gy
            end
        end
    end

    return contextmenu
end

local event = require("event")
function _sleep(time, object)
    -- event.pull until the time is up. If there is event, then onevent it
    local start = computer.uptime()
    local f = true
    while computer.uptime() - start < time or f do
        f = false
        local event = { event.pull(time - (computer.uptime() - start)) }
        if event[1] then
            if event[1] == "touch" then
                if object then
                    object.onEvent({ type = "touch", x = event[3], y = event[4] })
                end
            end
            if event[1] == "key_down" then
                if object then
                    object.onEvent({ type = "key_down", key = event[3], keycode = event[4] })
                end
            end
            if event[1] == "key_up" then
                if object then
                    object.onEvent({ type = "key_up", key = event[3], keycode = event[4] })
                end
            end
            if event[1] == "drop" then
                if object then
                    object.onEvent({ type = "drop", path = event[6] })
                end
            end
            if event[1] == "drag" then
                if object then
                    object.onEvent({ type = "drag", path = event[6], _x = event[3], _y = event[4] })
                end
            end
        end
    end
end

function gui.eventLoop(object)
    gui.root = object

    local buf = gpu.allocateBuffer(buffer.width, buffer.height)


    while true do
        --_sleep(1/20, object)
        -- get the time the tick takes
        local start = computer.uptime()
        gpu.setActiveBuffer(buf)
        --kern_info("beforedraw")

        object._update()
        object.update()

        object._beforeDraw()
        object.beforeDraw()
        -- kern_info("draw")
        object.draw()

        object.afterDraw()
        object._afterDraw()

        local t, e = gpu.bitblt()
        gpu.setActiveBuffer(0)
        if not t then
            kern_log("Issue with render gui: " .. e, "warn")
        end
        --kern_info("afterdraw")
        -- -- buffer.draw()
        local ende = computer.uptime()
        local time = ende - start
        --gpu.set(1,1,tostring(time))
        --kern_info("time: "..tostring(time))

        _sleep(0, object)
    end
end

require("process").new(
    "GuiTicker",
    [[
local event = require("event")
local gui = require("newgui")
gui.eventLoop(gui.workspace)
        ]]
)

gui.workspace = gui.panel(1, 1, buffer.width, buffer.height, 0x555555)
gui.workspace._gx = 1
gui.workspace._gy = 1
gui.workspace.alwaysDraw = true



return gui
