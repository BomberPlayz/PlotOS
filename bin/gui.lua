local gui = {}
gui.click = false
gui.cx = 0
gui.cy = 0
local buffering = require("doublebuffering")
local gpu = require("driver").load("gpu")
local event = require("event")


event.listen("touch",function(event,_,x,y,btn)
    print("touch")
    gui.click = true
    print(tostring(gui.click))
    gui.cx = x
    gui.cy = y


end)

event.listen("drag",function(event,_,x,y,btn)


    gui.cx = x
    gui.cy = y


end)

event.listen("drop",function(event,_,x,y,btn)
    gui.click = false

    gui.cx = x
    gui.cy = y


end)

gui.isInRect = function(x,y,w,h,px,py)
    --print("x: "..x.." y: "..y.." mx: "..x+w.." my: "..y+h.." mousex: "..gui.cx.." mousey: "..gui.cy)
    if px >= x and px <= x+w and py >= y and py <= y+h then
        return true
    else
        return false
    end
end

gui.component = function()
    local obj = {  }

    obj.x = 0
    obj.y = 0
    obj.gx = 0
    obj.gy = 0
    obj.width = 1
    obj.height = 1
    obj.dirty = true

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

    function obj.move(x,y)
        obj.x = x
        obj.y = y
        obj.dirty = true
    end

    obj._mousedown = function(x,y,btn)
        if obj.onMouseDown then
            obj.onMouseDown(x,y,btn)
        end
    end

    obj._onmouseup = function(x,y,btn)
        if obj.onMouseUp then
            obj.onMouseUp(x,y,btn)
        end
    end







    return obj
end

gui.container = function(x,y,w,h)
    local obj = gui.component()
    obj.x = x
    obj.y = y
    obj.width = w
    obj.height = h
    obj.children = {}

    function obj:addChild(child)
        child.parent = obj
        child._parentIndex = #obj.children+1
        table.insert(obj.children, child)
    end

    obj._draw = function(buf)
        for k,v in ipairs(obj.children) do
            v.x = v.x + obj.x
            v.y = v.y + obj.y
            v.gx = v.x
            v.gy = v.y
            if v.dirty then
                v._draw(buf)

            end
            v.x = v.x - obj.x
            v.y = v.y - obj.y
        end
        obj.dirty = false
    end

    obj.checkDirty = function()
        local isDirt = false
        for k,v in ipairs(obj.children) do
            v.checkDirty()
            if v.dirty then
                isDirt = true
            end
        end
        obj.dirty = isDirt
    end

    obj.tick = function()
        for k=#obj.children,1,-1 do
            local v = obj.children[k]
            v.x = v.x + obj.x
            v.y = v.y + obj.y
            v.gx = v.x
            v.gy = v.y
            v._tick()
            v.x = v.x - obj.x
            v.y = v.y - obj.y
        end
    end

    return obj

end

gui.text = function(x,y,text)
    local obj = gui.component()
    obj.x = x
    obj.y = y
    obj.textColor = 0xffffff
    obj.backColor = 0x000000
    obj.text = text
    obj.width = string.len(text)

    obj._draw = function(buf)
        buf.setForeground(obj.textColor)
        buf.setBackground(obj.backColor)
        buf.set(obj.x, obj.y, obj.text)

        obj.dirty = false
    end


    


    


    return obj
end

gui.panel = function(x,y,w,h,color)
    local obj = gui.component()
    obj.x = x
    obj.y = y
    obj.width = w
    obj.height = h
    obj.color = color or 0xffffff
    obj.dirty = true
    obj._draw = function(buf)
        buf.setBackground(obj.color)
        buf.fill(obj.x,obj.y,obj.width,obj.height," ")

        obj.dirty = false
    end






    return obj
end

gui.button = function(x,y,w,h,text)
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
        buf.setForeground(obj.isPressed and obj.ptextColor or obj.textColor)
        buf.setBackground(obj.isPressed and obj.pbackColor or obj.backColor)
        buf.fill(obj.x,obj.y,obj.width,obj.height, " ")
        buf.set(obj.x,obj.y,text)
        obj.dirty = false
    end


    obj.onClick = function()

    end


    obj.tick = function()
        if obj.isPressed then
            obj.isPressed = false
            obj.dirty = true
            obj.onClick()
        end
        if gui.click and gui.isInRect(obj.x,obj.y,obj.width,obj.height,gui.cx,gui.cy) and clickCooldown < 1 then
           -- gui.click = false
            obj.dirty = true
            obj.isPressed = true
            clickCooldown = 10


        end
        if clickCooldown > 0 then clickCooldown = clickCooldown-1 end
    end

    return obj
end

gui.window = function(x,y,w,h,title)
    -- a simple window component. Should have a draggable titlebar, and a close button.
    local obj = gui.container(x,y,w,h)
    obj.title = title or "Untitled window"
    obj.titlebar = gui.container(0,0,w,1)
    obj.titlebar:addChild(gui.panel(0,0,obj.titlebar.width, 1, 0xCCCCCC))
    local txt = gui.text(0,0,obj.title)
    txt.textColor = 0xCCCCCC
    obj.titlebar:addChild(txt)

    local closeButton = gui.button(w-1,0,1,1,"X")
    closeButton.onClick = function()
        -- close the window
        obj.close()
    end

    obj.close = function()
        -- window close logic
        table.remove(obj.parent, obj._parentIndex)
    end
    obj.titlebar:addChild(closeButton)

    obj:addChild(obj.titlebar)

    obj.container = gui.container(0,1,w,h-1)
    obj.container:addChild(gui.panel(0,0,obj.container.width,obj.container.height,0xffffff))
    obj:addChild(obj.container)
    obj.isDrag = false
    obj.drag = {sx=0,sy=0}

    function obj.tick()
       -- print("winticc")

        -- tick all child elements, like in a simple container, then handle drag logic.
        for k=#obj.children,1,-1 do
            local v = obj.children[k]
            v.x = v.x + obj.x
            v.y = v.y + obj.y
            v._tick()
            v.x = v.x - obj.x
            v.y = v.y - obj.y
        end

        -- get dragging work.
        --print(tostring(gui.isInRect(obj.x,obj.y,obj.width,obj.height,gui.cx,gui.cy)))
        print(tostring(gui.click))
        if gui.isInRect(obj.x,obj.y,obj.width,obj.height,gui.cx,gui.cy) and gui.click then
            print("drag")
            if not obj.isDrag then
                obj.isDrag = true
                obj.drag.sx = gui.cx
                obj.drag.sy = gui.cy
            end
            obj.x = obj.x + (gui.cx - obj.drag.sx)
            obj.y = obj.y + (gui.cy - obj.drag.sy)
            --obj.drag.sx = gui.cx
            --obj.drag.sy = gui.cy
        elseif not gui.click then
            obj.isDrag = false
        end


    end

    return obj
end



return gui