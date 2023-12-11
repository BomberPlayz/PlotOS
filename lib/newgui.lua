local dbuf = require("doublebuffering")
local reg = require("registry")
local gpu = require("driver").load("gpu")


local buffer = gpu
buffer.width, buffer.height = buffer.getResolution()


buffer.setBackground(0x000000)
buffer.fill(1,1,buffer.width,buffer.height," ")
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



function gui.component(x,y,w,h)
    local comp = {}
    comp.x = x
    comp.y = y
    comp.w = w
    comp.h = h

    comp._gx = 0
    comp._gy = 0

    comp.draw = function() end
    comp.beforeDraw = function() end
    comp.afterDraw = function() end
    comp.onEvent = function() end

    comp.dirty = true

    comp.parent = nil

    comp.enabled = true

    comp.eventbus = EventEmitter()

    comp.setDirty = function()
        comp.dirty = true

    end

    comp.requestedDraws = {}


    -- requests a draw in a specified area.
    comp.requestDraw = function(x,y,w,h)
        -- check if requestedDraws doesnt have an entry for this x y w h
        local found = false
        for _,v in ipairs(comp.requestedDraws) do
            if v[1] == x and v[2] == y and v[3] == w and v[4] == h then
                found = true
                break
            end
        end
        if not found then
            table.insert(comp.requestedDraws, {x,y,w,h})
        end
    end

    return comp
end

function gui.container(x,y,w,h)
    local cont = gui.component(x,y,w,h)
    cont.children = {}

    cont.draw = function(special)




         buffer.setMask(cont.x, cont.y, cont.w, cont.h)



        for _, child in ipairs(cont.children) do
            -- check if the child is not obscured by another child. The other child should have a higher index in the table.
            -- check from the root object. --

            if child.enabled then

                
                child._gx = child.x+cont.x
                child._gy = child.y+cont.y

                if child.dirty then
                    child.draw(special)
                end
                

            end



        end





         buffer.setMask(0,0,buffer.width,buffer.height)


    end

    cont.onEvent = function(event)
        -- loop in an inverse order and check if the event has an x and y. If so then when a child gets the event, it won't propogate further.
        for i = #cont.children, 1, -1 do
            local child = cont.children[i]
            if child.enabled then
                if event.x and event.y and event.x >= child._gx and event.x < child._gx + child.w and event.y >= child._gy and event.y < child._gy + child.h then
                    child.x = cont.x + child.x
                    child.y = cont.y + child.y
                    child._gx = child.x
                    child._gy = child.y
                    child.onEvent(event)
                    child.x = child.x - cont.x
                    child.y = child.y - cont.y
                    return
                else
                    if not (event.x and event.y) then
                        child.x = cont.x + child.x
                        child.y = cont.y + child.y
                        child._gx = child.x
                        child._gy = child.y
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

    cont.beforeDraw = function()

        for i, child in ipairs(cont.children) do
            if child.enabled then
                
                child._gx = child.x+cont.x
                child._gy = child.y+cont.y
                --kern_info("child x: " .. child.x .. " child y: " .. child.y..", child id: " .. i)
                child.beforeDraw()
                

            end
        end
    end

    cont.afterDraw = function()
        for i, child in ipairs(cont.children) do
            if child.enabled then
                
                child._gx = child.x+cont.x
                child._gy = child.y+cont.y
                child.afterDraw()
                

            end
        end
    end

    cont.addChild = function(child)
        child.parent = cont
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

function gui.button(x,y,w,h,text)
    local btn = gui.component(x,y,w,h)
    btn.text = text

    btn.clicked = false
    btn.clickTick = false

    btn.color = 0xaaaaaa
    btn.foreColor = 0x000000

    btn.draw = function()
        -- if the button is clicked then the color is a bit darker so subtract

        if btn.clicked then
            buffer.setForeground(btn.foreColor)
            buffer.setBackground(btn.color - 0x111111)

            btn.clicked = false
            btn.dirty = true

        else
            buffer.setForeground(btn.foreColor)
            buffer.setBackground(btn.color)
        end

        buffer.fill(btn.x, btn.y, btn.w, btn.h, " ")
        -- center the text
        buffer.set(btn.x + math.floor(btn.w / 2) - math.floor(#btn.text / 2), btn.y + math.floor(btn.h / 2), btn.text)









    end

    btn.onEvent = function(event)
        if event.type == "touch" then
            btn.clicked = true

            btn.eventbus.emit("click", {x = event.x - btn.x, y = event.y - btn.y})

            btn.dirty = true


        end

    end

    return btn
end

function gui.label(x,y,w,h,text)
    local lbl = gui.component(x,y,w,h)
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

function gui.panel(x,y,w,h, color, char)
    local pnl = gui.container(x,y,w,h)

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
                
                child._gx = child.x+pnl.x
                child._gy = child.y+pnl.y

                if child.dirty then
                    child.draw(special)
                end
                

            end



        end





        buffer.setMask()
    end

    return pnl
end

function gui.progressBar(x,y,w,h, max)
    local bar = gui.component(x,y,w,h)

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

function gui.window(x,y,w,h)
    local win = gui.container(x,y,w,h)

    local titleBar = gui.panel(0, 0, w, 1, reg.get("system/ui/window/titlebar_color"))
    local title = gui.label(0,0,w,1,"Window")
    local closeButton = gui.button(w - 1,0,1,1,"x")

    win.buffer = gpu.allocateBuffer(w, h)
    local lastbuf = gpu.getActiveBuffer()


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

        -- remove the window from the parent
        win.parent.removeChild(win)
        win.isClosed = true
    end

    closeButton.eventbus.on("click", function()
        win.close()

    end)

    local content = gui.panel(0,1,w,h - 1)
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
            if reg.get("system/ui/window/drag_borders") == 1 then
                content.enabled = false
                con.enabled = true
            end
        elseif event.type == "drag" then
            if win.dragging then
                -- use gui.root.requestDraw to request a draw at the place where the window was before. Don't include the current position


                -- this is so the window won't leave artifacts behind
                -- gui.root.requestDraw args: x, y, w, h
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
            if reg.get("system/ui/window/drag_borders") == 1 then
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
                    child._gx = child.x
                    child._gy = child.y
                    child.onEvent(event)
                    child.x = child.x - titleBar.x
                    child.y = child.y - titleBar.y
                    return
                else
                    if not (event.x and event.y) then
                        child.x = titleBar.x + child.x
                        child.y = titleBar.y + child.y
                        child._gx = child.x
                        child._gy = child.y
                        child.onEvent(event)
                        child.x = child.x - titleBar.x
                        child.y = child.y - titleBar.y
                    end
                end
                if child.dirty then
                    win.dirty = true
                end

            end
        end
    end

    win.onEvent = function(event)



        for i = #win.children, 1, -1 do
            local child = win.children[i]
            if child.enabled then
                if event.x and event.y and event.x >= child._gx and event.x < child._gx + child.w and event.y >= child._gy and event.y < child._gy + child.h then

                    child.x = win.x + child.x
                    child.y = win.y + child.y
                    child._gx = child.x
                    child._gy = child.y
                    child.onEvent(event)
                    child.x = child.x - win.x
                    child.y = child.y - win.y
                    return
                else
                    if not (event.x and event.y) then
                        child.x = win.x + child.x
                        child.y = win.y + child.y
                        child._gx = child.x
                        child._gy = child.y
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

    win.beforeDraw = function()
        lastbuf = gpu.getActiveBuffer()
        gpu.setActiveBuffer(win.buffer)
        --[[if win.doRequestMove then
            gui.root.requestDraw(win.lastX, win.lastY, win.w, win.h)
            win.doRequestMove = false
        end]]
        if reg.get("system/ui/window/shadow") == 1 or true then
            --local lastbg = buffer.getBackground()
            --buffer.setBackground(0x000000)
            --local lastMask = buffer.getMask()
           -- -- buffer.setMask(0,0,buffer.width,buffer.height)
            --buffer.fill(win.w + 1, win.y + 1, 1, win.h, " ")
            --buffer.fill(win.x + 1, win.h + 1, win.w, 1, " ")
            ---- buffer.setMask(lastMask)
            --buffer.setBackground(lastbg)
            
        end
    end

    win.afterDraw = function()
        
        buffer.bitblt(lastbuf, win._gx, win._gy, win.w, win.h, win.buffer, 1,1)
        gpu.setActiveBuffer(lastbuf)
    end

    win.setTitle = function(title)
        win.title.text = title
        win.title.setDirty()
    end



    return win


end

function gui.treeNode(text)
    local node = gui.container(0,0,0,0)
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


local event = require("event")
function _sleep(time, object)
    -- event.pull until the time is up. If there is event, then onevent it
    local start = computer.uptime()
    local f = true
    while computer.uptime() - start < time or f do
        f = false
        local event = {event.pull(time - (computer.uptime() - start))}
        if event[1] then
            if event[1] == "touch" then
                if object then
                    object.onEvent({type = "touch", x = event[3], y = event[4]})
                end
            end
            if event[1] == "key_down" then
                if object then
                    object.onEvent({type = "key_down", key = event[4]})
                end
            end
            if event[1] == "key_up" then
                if object then
                    object.onEvent({type = "key_up", key = event[4]})
                end
            end
            if event[1] == "drop" then
                if object then
                    object.onEvent({type = "drop", path = event[6]})
                end
            end
            if event[1] == "drag" then
                if object then
                    object.onEvent({type = "drag", path = event[6], _x = event[3], _y = event[4]})
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
        object.beforeDraw()
       -- kern_info("draw")
        object.draw()

        object.afterDraw()
        
        local t, e = gpu.bitblt()
        gpu.setActiveBuffer(0)
        if not t then
            kern_info("Issue with render gui: "..e, "warn")
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

	gui.workspace = gui.panel(0, 0, buffer.width, buffer.height, 0x555555)


	return gui