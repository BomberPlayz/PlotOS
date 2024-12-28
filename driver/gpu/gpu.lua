

local ret = {}

ret.cp = {}



ret.compatible = function(adr)
    return ret.cp.proxy(adr).type == "gpu"
end

ret.driverProc = {}


ret.getName = function()
    return "MightyPirates GmbH OC GPU Driver by PixelTech Inc."
end

ret.getVersion = function()
    return 4
end

local index = function(x,y,w)
    return x + ((y-1)*w)
end

ret.new = function(adr)
    local com = ret.cp.proxy(adr)

    local drv = {}

    local w,h = com.getResolution()

    drv.mask = {
        x = 0,
        y = 0,
        w = w,
        h = h
    }

    drv.setMask = function(x,y,w,h)
       --[[ if not x then
            drv.mask = {
                x = 0,
                y = 0,
                w = drv.width,
                h = drv.height
            }
            return
        end
        drv.mask.x = x
        drv.mask.y = y
        drv.mask.w = w
        drv.mask.h = h]]
    end

    drv.getMask = function()
        return drv.mask.x,drv.mask.y,drv.mask.w,drv.mask.h
    end

    drv.bind = function(adr)
        return com.bind(adr)
    end

    drv.getScreen = function()
        return com.getScreen()
    end

    drv.getBackground = function()
        return com.getBackground()
    end

    drv.setBackground = function(color, palet)
        return com.setBackground(color,palet)
    end

    drv.getForeground = function()
        return com.getForeground()
    end

    drv.setForeground = function(color, palet)
        return com.setForeground(color,palet)
    end

    drv.getPaletteColor = function(i)
        return com.getPaletteColor(i)
    end

    drv.setPaletteColor = function(i,val)
        return com.setPaletteColor(i,val)
    end

    drv.maxDepth = function()
        return com.maxDepth()
    end

    drv.getDepth = function()
        return com.getDepth()
    end

    drv.setDepth = function(d)
        return com.setDepth(d)
    end

    drv.maxResolution = function()
        return com.maxResolution()
    end

    drv.getResolution = function()
        return com.getResolution()
    end

    drv.setResolution = function(w,h)
        return com.setResolution(w,h)
    end

    drv.getViewport = function()
        return com.getViewport()
    end

    drv.setViewport = function(w,h)
        return com.setViewport(w,h)
    end

    drv.get = function(x,y)
       -- error("terserert")

        return com.get(x,y)
    end

    drv.set = function(x,y,c, vertical)
        --printk("set: "..x..", "..y..", "..c)
        -- respect the buffer
        -- if c would be out of bounds, trim it to the mask

        -- why do we have these masks or vertical sets anyways?? the masks dont even offset the pos
        if y > drv.mask.h+drv.mask.y then
            return
        end

        if y < drv.mask.y and not vertical then
            return
        end

        if x < drv.mask.x then
            c = string.sub(c,drv.mask.x-x+1)
            x = drv.mask.x
        end

        if x > drv.mask.w+drv.mask.x then
            return
        end

        if x+#c-1 > drv.mask.w+drv.mask.x then
            c = string.sub(c,1,drv.mask.w+drv.mask.x-x+1)
        end
        
        if vertical then
            if y < drv.mask.y then
                local diff = drv.mask.y-y
                y = drv.mask.y
                c = string.sub(c,diff+1)
            end

            if y+#c > drv.mask.h+drv.mask.y then
                local diff = y+#c - (drv.mask.h+drv.mask.y)
                c = string.sub(c,1,#c-diff)
            end
        end

        if vertical then
            for i = 1,#c do
                com.set(x,y+i-1,string.sub(c,i,i))
            end
            return
        end

        return com.set(x,y,c)
    end

    drv.copy = function(x,y,w,h,tx,ty)
        return com.copy(x,y,w,h,tx,ty)
    end
    
    drv.fill = function(x,y,w,h,c)
        -- respect the buffer
        x = math.max(x,drv.mask.x)
        y = math.max(y,drv.mask.y)
        w = math.min(w,drv.mask.w)
        h = math.min(h,drv.mask.h)


        return com.fill(x,y,w,h,c)
    end

    drv.getActiveBuffer = function()
        return com.getActiveBuffer()
    end

    drv.setActiveBuffer = function(i)
        return com.setActiveBuffer(i)
    end

    drv.buffers = function()
        return com.buffers()
    end

    drv.allocateBuffer = function(w,h)
        return com.allocateBuffer(w,h)
    end

    drv.freeBuffer = function(i)
        return com.freeBuffer(i)
    end

    drv.freeAllBuffers = function()
        return com.freeAllBuffers()
    end

    drv.totalMemory = function()
        return com.totalMemory()
    end

    drv.freeMemory = function()
        return com.freeMemory()
    end

    drv.getBufferSize = function(i)
        return com.getBufferSize(i)
    end

    drv.bitblt = function(dst,col,row,w,h,src,fromcol,fromrow)
        --printk("bitblt")
        --printk(dst..", "..col..", "..row..", "..w..", "..h)
        return com.bitblt(dst,col,row,w,h,src,fromcol,fromrow)
    end

    drv.copy = function(sx,sy,ex,ey,tx,ty)
        return com.copy(sx,sy,ex,ey,tx,ty)
    end




    return drv
end

return ret