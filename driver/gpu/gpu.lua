

local ret = {}

ret.cp = {}



ret.compatible = function(adr)
    return ret.cp.proxy(adr).type == "gpu"
end

ret.driverProc = {}


ret.getName = function()
    return "MightyPirates GmbH OC GPU Driver by InPixel Inc."
end

ret.getVersion = function()
    return 3
end

local index = function(x,y,w)
    return x + ((y-1)*w)
end

ret.new = function(adr)
    local com = ret.cp.proxy(adr)

    local drv = {}

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
        return com.get(x,y)
    end

    drv.set = function(x,y,v,vv)
        return com.set(x,y,v,vv)
    end

    drv.copy = function(x,y,w,h,tx,ty)
        return com.copy(x,y,w,h,tx,ty)
    end
    
    drv.fill = function(x,y,w,h,c)
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
        return com.bitblt(dst,col,row,w,h,src,fromcol,fromrow)
    end

    drv.copy = function(sx,sy,ex,ey,tx,ty)
        return com.copy(sx,sy,ex,ey,tx,ty)
    end


    return drv
end

return ret